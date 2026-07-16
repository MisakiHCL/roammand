#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

smoke=scripts/run_m7_smoke.sh
soak=scripts/run_m7_soak.sh
reconnect=scripts/check_m7_reconnect.sh

fail() {
  echo "M7 harness contract failed: $1" >&2
  exit 1
}

for script in "$smoke" "$soak" "$reconnect"; do
  [[ -x "$script" ]] || fail "$script is missing or not executable"
  bash -n "$script" || fail "$script has invalid syntax"
done

for scenario in \
  direct-and-turn \
  transient-recovery \
  host-restart \
  thirty-second-failure \
  busy-session \
  revocation \
  permissions \
  ten-lifecycle-cycles; do
  rg -q "$scenario" "$smoke" || fail "smoke scenario is missing: $scenario"
done
for command in 'flutter test' 'cargo test' 'go test'; do
  rg -q "$command" "$smoke" || fail "smoke runner does not invoke $command"
done

rg -q '^DEFAULT_DEVICES=5$' "$soak" || fail "soak default must be five devices"
rg -q '^DEFAULT_DURATION_SECONDS=604800$' "$soak" || fail "soak default must be seven days"
rg -q '^DEFAULT_SAMPLE_INTERVAL_SECONDS=60$' "$soak" || fail "soak sampling interval is not explicit"
rg -q 'rss_kb,threads,fds,client_queue_depth,log_bytes' "$soak" || fail "soak CSV omits required metrics"
rg -q '^MAX_CSV_BYTES=' "$soak" || fail "soak CSV is not bounded"
rg -q '^MAX_LOG_BYTES=' "$soak" || fail "soak logs are not bounded"
rg -q '^GROWTH_SAMPLE_WINDOW=' "$soak" || fail "soak growth window is missing"
rg -q 'monotonic resource growth' "$soak" || fail "soak does not fail monotonic growth"
rg -q 'resource threshold exceeded' "$soak" || fail "soak does not fail thresholds"
rg -q -- '--validate-only' "$soak" || fail "soak validation-only mode is missing"
if rg -n 'PASS.*validate|validate.*PASS' "$soak"; then
  fail "validation-only mode must not claim a real soak passed"
fi

echo "M7 harness contract passed"
