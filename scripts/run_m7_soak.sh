#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

DEFAULT_DEVICES=5
DEFAULT_DURATION_SECONDS=604800
DEFAULT_SAMPLE_INTERVAL_SECONDS=60
MAX_CSV_BYTES=4194304
MAX_LOG_BYTES=10485760
GROWTH_SAMPLE_WINDOW=10
MAX_RSS_KB="${M7_SOAK_MAX_RSS_KB:-262144}"
MAX_THREADS="${M7_SOAK_MAX_THREADS:-128}"
MAX_FDS="${M7_SOAK_MAX_FDS:-512}"
MAX_CLIENT_QUEUE_DEPTH="${M7_SOAK_MAX_CLIENT_QUEUE_DEPTH:-16}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
devices="$DEFAULT_DEVICES"
duration_seconds="$DEFAULT_DURATION_SECONDS"
sample_interval_seconds="$DEFAULT_SAMPLE_INTERVAL_SECONDS"
output_dir="${M7_SOAK_OUTPUT_DIR:-${TMPDIR:-/tmp}/roammand-m7-soak}"
validate_only=false

usage() {
  echo "Usage: $0 [--validate-only] [--devices N] [--duration-seconds N] [--sample-interval N] [--output-dir PATH]"
}

fail() {
  echo "M7 soak failed: $1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only)
      validate_only=true
      shift
      ;;
    --devices)
      [[ $# -ge 2 ]] || fail "--devices requires a value"
      devices="$2"
      shift 2
      ;;
    --duration-seconds)
      [[ $# -ge 2 ]] || fail "--duration-seconds requires a value"
      duration_seconds="$2"
      shift 2
      ;;
    --sample-interval)
      [[ $# -ge 2 ]] || fail "--sample-interval requires a value"
      sample_interval_seconds="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || fail "--output-dir requires a value"
      output_dir="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown argument: $1"
      ;;
  esac
done

for value_name in devices duration_seconds sample_interval_seconds MAX_RSS_KB MAX_THREADS MAX_FDS MAX_CLIENT_QUEUE_DEPTH; do
  value="${!value_name}"
  [[ "$value" =~ ^[1-9][0-9]*$ ]] || fail "$value_name must be a positive integer"
done
[[ "$devices" -le "$MAX_CLIENT_QUEUE_DEPTH" ]] || fail "device count exceeds the client queue threshold"

for command in go rg ps awk wc tail date mktemp mkdir seq find mv sleep; do
  command -v "$command" >/dev/null 2>&1 || fail "required command is unavailable: $command"
done
if [[ ! -d /proc/$$/fd ]]; then
  command -v lsof >/dev/null 2>&1 || fail "lsof is required when /proc is unavailable"
fi

if [[ "$validate_only" == true ]]; then
  echo "M7 soak configuration validated; no soak was run"
  exit 0
fi

mkdir -p "$output_dir"
metrics_file="$output_dir/metrics.csv"
server_log="$output_dir/signaling.log"
client_log="$output_dir/clients.log"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/roammand-m7-soak.XXXXXX")"
server_pid=""

cleanup() {
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT INT TERM

(
  cd "$repo_root/services/signaling"
  CGO_ENABLED=0 go build -trimpath -o "$work_dir/signaling" ./cmd/signaling
  CGO_ENABLED=0 go build -trimpath -o "$work_dir/simulate" ./cmd/simulate
)

: > "$server_log"
: > "$client_log"
SIGNALING_LISTEN_ADDR=127.0.0.1:0 "$work_dir/signaling" >"$server_log" 2>&1 &
server_pid=$!

endpoint=""
for _ in $(seq 1 100); do
  endpoint="$(rg -o -m1 'ws://127\.0\.0\.1:[0-9]+/v1/connect' "$server_log" || true)"
  [[ -n "$endpoint" ]] && break
  kill -0 "$server_pid" 2>/dev/null || fail "signaling exited before readiness"
  sleep 0.1
done
[[ -n "$endpoint" ]] || fail "signaling readiness timed out"

printf '%s\n' 'timestamp_utc,rss_kb,threads,fds,client_queue_depth,log_bytes' > "$metrics_file"
start_seconds="$(date +%s)"
deadline_seconds=$((start_seconds + duration_seconds))
previous_rss=0
previous_fds=0
rss_growth_samples=0
fd_growth_samples=0

file_bytes() {
  wc -c < "$1" | awk '{print $1}'
}

rotate_log() {
  log_file="$1"
  log_bytes="$(file_bytes "$log_file")"
  if [[ "$log_bytes" -gt "$MAX_LOG_BYTES" ]]; then
    tail -c "$MAX_LOG_BYTES" "$log_file" > "$log_file.tmp"
    mv "$log_file.tmp" "$log_file"
  fi
}

process_threads() {
  if [[ -d "/proc/$server_pid/task" ]]; then
    find "/proc/$server_pid/task" -mindepth 1 -maxdepth 1 -type d | wc -l | awk '{print $1}'
  elif ps -o thcount= -p "$server_pid" >/dev/null 2>&1; then
    ps -o thcount= -p "$server_pid" | awk '{print $1}'
  else
    ps -M -p "$server_pid" | awk 'NR > 1 {count += 1} END {print count + 0}'
  fi
}

process_fds() {
  if [[ -d "/proc/$server_pid/fd" ]]; then
    find "/proc/$server_pid/fd" -mindepth 1 -maxdepth 1 | wc -l | awk '{print $1}'
  else
    lsof -p "$server_pid" -Fn | rg -c '^f[0-9]+' || true
  fi
}

while [[ "$(date +%s)" -lt "$deadline_seconds" ]]; do
  kill -0 "$server_pid" 2>/dev/null || fail "signaling stopped during soak"
  rotate_log "$client_log"

  client_pids=()
  for _ in $(seq 1 "$devices"); do
    (SIGNALING_ENDPOINT="$endpoint" "$work_dir/simulate" >>"$client_log" 2>&1) &
    client_pids+=("$!")
  done
  client_queue_depth="${#client_pids[@]}"
  client_failures=0
  for client_pid in "${client_pids[@]}"; do
    if ! wait "$client_pid"; then
      client_failures=$((client_failures + 1))
    fi
  done
  [[ "$client_failures" -eq 0 ]] || fail "client queue reported $client_failures failed simulations"

  rss_kb="$(ps -o rss= -p "$server_pid" | awk '{print $1 + 0}')"
  threads="$(process_threads)"
  fds="$(process_fds)"
  rotate_log "$server_log"
  rotate_log "$client_log"
  log_bytes=$(( $(file_bytes "$server_log") + $(file_bytes "$client_log") ))

  if [[ "$rss_kb" -gt "$MAX_RSS_KB" || "$threads" -gt "$MAX_THREADS" || "$fds" -gt "$MAX_FDS" || "$client_queue_depth" -gt "$MAX_CLIENT_QUEUE_DEPTH" || "$log_bytes" -gt "$MAX_LOG_BYTES" ]]; then
    fail "resource threshold exceeded"
  fi

  if [[ "$previous_rss" -gt 0 && "$rss_kb" -gt "$previous_rss" ]]; then
    rss_growth_samples=$((rss_growth_samples + 1))
  else
    rss_growth_samples=0
  fi
  if [[ "$previous_fds" -gt 0 && "$fds" -gt "$previous_fds" ]]; then
    fd_growth_samples=$((fd_growth_samples + 1))
  else
    fd_growth_samples=0
  fi
  if [[ "$rss_growth_samples" -ge "$GROWTH_SAMPLE_WINDOW" || "$fd_growth_samples" -ge "$GROWTH_SAMPLE_WINDOW" ]]; then
    fail "monotonic resource growth detected"
  fi
  previous_rss="$rss_kb"
  previous_fds="$fds"

  printf '%s,%s,%s,%s,%s,%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$rss_kb" "$threads" "$fds" "$client_queue_depth" "$log_bytes" >> "$metrics_file"
  [[ "$(file_bytes "$metrics_file")" -le "$MAX_CSV_BYTES" ]] || fail "metrics CSV exceeded its size bound"

  remaining=$((deadline_seconds - $(date +%s)))
  [[ "$remaining" -le 0 ]] && break
  sleep_seconds="$sample_interval_seconds"
  [[ "$remaining" -lt "$sleep_seconds" ]] && sleep_seconds="$remaining"
  sleep "$sleep_seconds"
done

echo "M7 soak completed successfully; metrics: $metrics_file"
