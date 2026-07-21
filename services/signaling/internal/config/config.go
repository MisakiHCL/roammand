// SPDX-License-Identifier: AGPL-3.0-only

package config

import (
	"fmt"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"time"
)

const (
	DefaultListenAddress = "127.0.0.1:8080"

	RegistrationTimeout = 5 * time.Second
	MessageReadTimeout  = 10 * time.Second
	HeartbeatInterval   = 15 * time.Second
	PresenceTimeout     = 45 * time.Second
	RendezvousTTL       = 2 * time.Minute
	SweepInterval       = time.Second
	RateLimitWindow     = time.Minute
	ShutdownTimeout     = 10 * time.Second
	MaxShutdownTimeout  = time.Minute

	OutboundQueueCapacity       = 64
	PairingAttemptsPerIP        = 30
	PairingAttemptsPerLookupKey = 5
	RateLimitIPWindowCapacity   = 65_536
	RateLimitLookupCapacity     = 262_144
	MaxTrustedProxyCIDRs        = 16
	InboundRateLimitWindow      = time.Second
	InboundFramesPerConnection  = 256
	InboundBytesPerConnection   = 32 * 1024 * 1024
	InboundFramesPerIP          = 4_096
	InboundBytesPerIP           = 128 * 1024 * 1024
	InboundFramesGlobal         = 32_768
	InboundBytesGlobal          = 512 * 1024 * 1024
	InboundIPWindowCapacity     = 65_536
	DefaultMaxConnections       = 1_024
	MaximumMaxConnections       = 65_536
	DefaultMaxConnectionsPerIP  = 64
	DefaultMaxRendezvous        = 4_096
	MaximumMaxRendezvous        = 65_536
	DefaultMaxRendezvousPerHost = 4
	MaximumMaxRendezvousPerHost = 64

	DefaultGlobalOutboundByteBudget  = 64 * 1024 * 1024
	DefaultPerIPOutboundByteBudget   = 4 * 1024 * 1024
	OutboundFrameBudgetPerConnection = 2

	DefaultGlobalInFlightReadByteBudget = 64 * 1024 * 1024
	DefaultPerIPInFlightReadByteBudget  = 8 * 1024 * 1024
	InboundReadLimitProbeBytes          = 1
)

type Config struct {
	ListenAddress        string
	TLSCertificateFile   string
	TLSPrivateKeyFile    string
	TrustedProxyCIDRs    []netip.Prefix
	ShutdownTimeout      time.Duration
	MaxConnections       int
	MaxConnectionsPerIP  int
	MaxRendezvous        int
	MaxRendezvousPerHost int
}

func Load(getenv func(string) string) (Config, error) {
	config := Config{
		ListenAddress:        strings.TrimSpace(getenv("SIGNALING_LISTEN_ADDR")),
		TLSCertificateFile:   strings.TrimSpace(getenv("SIGNALING_TLS_CERT_FILE")),
		TLSPrivateKeyFile:    strings.TrimSpace(getenv("SIGNALING_TLS_KEY_FILE")),
		ShutdownTimeout:      ShutdownTimeout,
		MaxConnections:       DefaultMaxConnections,
		MaxConnectionsPerIP:  DefaultMaxConnectionsPerIP,
		MaxRendezvous:        DefaultMaxRendezvous,
		MaxRendezvousPerHost: DefaultMaxRendezvousPerHost,
	}
	if config.ListenAddress == "" {
		config.ListenAddress = DefaultListenAddress
	}
	if err := validateListenAddress(config.ListenAddress); err != nil {
		return Config{}, err
	}
	if (config.TLSCertificateFile == "") != (config.TLSPrivateKeyFile == "") {
		return Config{}, fmt.Errorf(
			"SIGNALING_TLS_CERT_FILE and SIGNALING_TLS_KEY_FILE must be configured together",
		)
	}
	trustedProxyCIDRs, err := parseTrustedProxyCIDRs(getenv("SIGNALING_TRUSTED_PROXY_CIDRS"))
	if err != nil {
		return Config{}, err
	}
	config.TrustedProxyCIDRs = trustedProxyCIDRs
	maxConnections, err := parseBoundedPositiveInt(
		getenv("SIGNALING_MAX_CONNECTIONS"),
		"SIGNALING_MAX_CONNECTIONS",
		DefaultMaxConnections,
		MaximumMaxConnections,
	)
	if err != nil {
		return Config{}, err
	}
	config.MaxConnections = maxConnections
	maxConnectionsPerIP, err := parseBoundedPositiveInt(
		getenv("SIGNALING_MAX_CONNECTIONS_PER_IP"),
		"SIGNALING_MAX_CONNECTIONS_PER_IP",
		DefaultMaxConnectionsPerIP,
		MaximumMaxConnections,
	)
	if err != nil {
		return Config{}, err
	}
	config.MaxConnectionsPerIP = maxConnectionsPerIP
	maxRendezvous, err := parseBoundedPositiveInt(
		getenv("SIGNALING_MAX_RENDEZVOUS"),
		"SIGNALING_MAX_RENDEZVOUS",
		DefaultMaxRendezvous,
		MaximumMaxRendezvous,
	)
	if err != nil {
		return Config{}, err
	}
	config.MaxRendezvous = maxRendezvous
	maxRendezvousPerHost, err := parseBoundedPositiveInt(
		getenv("SIGNALING_MAX_RENDEZVOUS_PER_HOST"),
		"SIGNALING_MAX_RENDEZVOUS_PER_HOST",
		DefaultMaxRendezvousPerHost,
		MaximumMaxRendezvousPerHost,
	)
	if err != nil {
		return Config{}, err
	}
	config.MaxRendezvousPerHost = maxRendezvousPerHost

	if encoded := strings.TrimSpace(getenv("SIGNALING_SHUTDOWN_TIMEOUT")); encoded != "" {
		parsed, err := time.ParseDuration(encoded)
		if err != nil {
			return Config{}, fmt.Errorf("parse SIGNALING_SHUTDOWN_TIMEOUT: %w", err)
		}
		if parsed <= 0 || parsed > MaxShutdownTimeout {
			return Config{}, fmt.Errorf(
				"SIGNALING_SHUTDOWN_TIMEOUT must be greater than zero and at most %s",
				MaxShutdownTimeout,
			)
		}
		config.ShutdownTimeout = parsed
	}
	return config, nil
}

func parseBoundedPositiveInt(encoded, name string, fallback, maximum int) (int, error) {
	encoded = strings.TrimSpace(encoded)
	if encoded == "" {
		return fallback, nil
	}
	value, err := strconv.Atoi(encoded)
	if err != nil || value <= 0 || value > maximum {
		return 0, fmt.Errorf("%s must be greater than zero and at most %d", name, maximum)
	}
	return value, nil
}

func parseTrustedProxyCIDRs(encoded string) ([]netip.Prefix, error) {
	encoded = strings.TrimSpace(encoded)
	if encoded == "" {
		return nil, nil
	}
	values := strings.Split(encoded, ",")
	if len(values) > MaxTrustedProxyCIDRs {
		return nil, fmt.Errorf("SIGNALING_TRUSTED_PROXY_CIDRS has too many entries")
	}
	prefixes := make([]netip.Prefix, 0, len(values))
	for _, value := range values {
		prefix, err := netip.ParsePrefix(strings.TrimSpace(value))
		if err != nil {
			return nil, fmt.Errorf("parse SIGNALING_TRUSTED_PROXY_CIDRS: %w", err)
		}
		if prefix.Bits() == 0 {
			return nil, fmt.Errorf(
				"SIGNALING_TRUSTED_PROXY_CIDRS must not trust an entire address family",
			)
		}
		prefixes = append(prefixes, prefix.Masked())
	}
	return prefixes, nil
}

func (config Config) TLSConfigured() bool {
	return config.TLSCertificateFile != ""
}

func validateListenAddress(address string) error {
	_, portText, err := net.SplitHostPort(address)
	if err != nil {
		return fmt.Errorf("parse SIGNALING_LISTEN_ADDR: %w", err)
	}
	port, err := strconv.Atoi(portText)
	if err != nil || port < 0 || port > 65535 {
		return fmt.Errorf("SIGNALING_LISTEN_ADDR has invalid port")
	}
	return nil
}
