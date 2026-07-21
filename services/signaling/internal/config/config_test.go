// SPDX-License-Identifier: AGPL-3.0-only

package config

import (
	"net/netip"
	"strconv"
	"testing"
	"time"
)

func TestLoadDefaults(t *testing.T) {
	config, err := Load(func(string) string { return "" })
	if err != nil {
		t.Fatal(err)
	}
	if config.ListenAddress != "127.0.0.1:8080" {
		t.Fatalf("listen address = %q", config.ListenAddress)
	}
	if config.ShutdownTimeout != 10*time.Second {
		t.Fatalf("shutdown timeout = %s", config.ShutdownTimeout)
	}
	if config.MaxConnections != DefaultMaxConnections ||
		config.MaxConnectionsPerIP != DefaultMaxConnectionsPerIP ||
		config.MaxRendezvous != DefaultMaxRendezvous ||
		config.MaxRendezvousPerHost != DefaultMaxRendezvousPerHost {
		t.Fatalf(
			"resource limits = (%d, %d, %d, %d)",
			config.MaxConnections,
			config.MaxConnectionsPerIP,
			config.MaxRendezvous,
			config.MaxRendezvousPerHost,
		)
	}
	if RendezvousTTL != 2*time.Minute {
		t.Fatalf("rendezvous TTL = %s", RendezvousTTL)
	}
}

func TestLoadOverrides(t *testing.T) {
	values := map[string]string{
		"SIGNALING_LISTEN_ADDR":             "localhost:9443",
		"SIGNALING_TLS_CERT_FILE":           "server.crt",
		"SIGNALING_TLS_KEY_FILE":            "server.key",
		"SIGNALING_TRUSTED_PROXY_CIDRS":     "127.0.0.0/8,::1/128",
		"SIGNALING_SHUTDOWN_TIMEOUT":        "15s",
		"SIGNALING_MAX_CONNECTIONS":         "128",
		"SIGNALING_MAX_CONNECTIONS_PER_IP":  "16",
		"SIGNALING_MAX_RENDEZVOUS":          "256",
		"SIGNALING_MAX_RENDEZVOUS_PER_HOST": "3",
	}
	config, err := Load(func(key string) string { return values[key] })
	if err != nil {
		t.Fatal(err)
	}
	if config.ListenAddress != values["SIGNALING_LISTEN_ADDR"] ||
		config.TLSCertificateFile != values["SIGNALING_TLS_CERT_FILE"] ||
		config.TLSPrivateKeyFile != values["SIGNALING_TLS_KEY_FILE"] ||
		len(config.TrustedProxyCIDRs) != 2 ||
		config.TrustedProxyCIDRs[0] != netip.MustParsePrefix("127.0.0.0/8") ||
		config.ShutdownTimeout != 15*time.Second ||
		config.MaxConnections != 128 ||
		config.MaxConnectionsPerIP != 16 ||
		config.MaxRendezvous != 256 ||
		config.MaxRendezvousPerHost != 3 {
		t.Fatalf("unexpected config: %+v", config)
	}
}

func TestLoadRejectsUnpairedTLSFiles(t *testing.T) {
	for name, values := range map[string]map[string]string{
		"certificate only": {"SIGNALING_TLS_CERT_FILE": "server.crt"},
		"key only":         {"SIGNALING_TLS_KEY_FILE": "server.key"},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := Load(func(key string) string { return values[key] }); err == nil {
				t.Fatal("Load accepted unpaired TLS files")
			}
		})
	}
}

func TestLoadRejectsInvalidValues(t *testing.T) {
	for name, values := range map[string]map[string]string{
		"listen address":   {"SIGNALING_LISTEN_ADDR": "not-an-address"},
		"zero timeout":     {"SIGNALING_SHUTDOWN_TIMEOUT": "0s"},
		"invalid timeout":  {"SIGNALING_SHUTDOWN_TIMEOUT": "eventually"},
		"invalid proxy":    {"SIGNALING_TRUSTED_PROXY_CIDRS": "loopback"},
		"all IPv4 proxies": {"SIGNALING_TRUSTED_PROXY_CIDRS": "0.0.0.0/0"},
		"all IPv6 proxies": {"SIGNALING_TRUSTED_PROXY_CIDRS": "::/0"},
		"zero connections": {"SIGNALING_MAX_CONNECTIONS": "0"},
		"too many connections": {
			"SIGNALING_MAX_CONNECTIONS": strconv.Itoa(MaximumMaxConnections + 1),
		},
		"zero connections per IP": {"SIGNALING_MAX_CONNECTIONS_PER_IP": "0"},
		"too many connections per IP": {
			"SIGNALING_MAX_CONNECTIONS_PER_IP": strconv.Itoa(MaximumMaxConnections + 1),
		},
		"zero rendezvous capacity": {"SIGNALING_MAX_RENDEZVOUS": "0"},
		"too much rendezvous capacity": {
			"SIGNALING_MAX_RENDEZVOUS": strconv.Itoa(MaximumMaxRendezvous + 1),
		},
		"invalid rendezvous limit": {"SIGNALING_MAX_RENDEZVOUS_PER_HOST": "many"},
		"too many rendezvous": {
			"SIGNALING_MAX_RENDEZVOUS_PER_HOST": strconv.Itoa(MaximumMaxRendezvousPerHost + 1),
		},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := Load(func(key string) string { return values[key] }); err == nil {
				t.Fatal("Load accepted invalid configuration")
			}
		})
	}
}
