// SPDX-License-Identifier: AGPL-3.0-only

package config

import (
	"net/netip"
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
	if RendezvousTTL != 2*time.Minute {
		t.Fatalf("rendezvous TTL = %s", RendezvousTTL)
	}
}

func TestLoadOverrides(t *testing.T) {
	values := map[string]string{
		"SIGNALING_LISTEN_ADDR":         "localhost:9443",
		"SIGNALING_TLS_CERT_FILE":       "server.crt",
		"SIGNALING_TLS_KEY_FILE":        "server.key",
		"SIGNALING_TRUSTED_PROXY_CIDRS": "127.0.0.0/8,::1/128",
		"SIGNALING_SHUTDOWN_TIMEOUT":    "15s",
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
		config.ShutdownTimeout != 15*time.Second {
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
		"listen address":  {"SIGNALING_LISTEN_ADDR": "not-an-address"},
		"zero timeout":    {"SIGNALING_SHUTDOWN_TIMEOUT": "0s"},
		"invalid timeout": {"SIGNALING_SHUTDOWN_TIMEOUT": "eventually"},
		"invalid proxy":   {"SIGNALING_TRUSTED_PROXY_CIDRS": "loopback"},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := Load(func(key string) string { return values[key] }); err == nil {
				t.Fatal("Load accepted invalid configuration")
			}
		})
	}
}
