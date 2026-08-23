// Package config parses and validates relayd's environment-based configuration.
//
// There is no config file on purpose: the deployment target is "a user drops a
// binary or container on a VPS", where environment variables are the one
// mechanism that works identically under systemd, Docker and a bare shell.
package config

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// MinTokenLength is the shortest accepted RELAY_TOKEN.
//
// The token is the only thing standing between the open internet and this
// server's bandwidth, and it is never rotated automatically, so a short one is
// rejected at startup rather than merely warned about.
const MinTokenLength = 32

// MaxConcurrentStreamsCap is the upper bound for RELAY_MAX_CONCURRENT_STREAMS.
// Each stream costs pipe buffers and handler goroutines; a typo should not be
// able to allocate millions of them.
const MaxConcurrentStreamsCap = 64

// Config holds every knob relayd exposes.
type Config struct {
	Listen  string
	Token   string
	TLSCert string
	TLSKey  string

	MaxConcurrentStreams int
	MaxStreamBytes       int64
	RateLimitBPS         int64

	StreamRendezvousTimeout time.Duration
	StreamIdleTimeout       time.Duration

	PairRatePerMin int

	LogLevel string
}

// TLSEnabled reports whether relayd should terminate TLS itself.
//
// Serving plain HTTP is the recommended setup: a reverse proxy in front of it
// handles certificates.
func (c *Config) TLSEnabled() bool {
	return c.TLSCert != "" && c.TLSKey != ""
}

// Getenv matches os.Getenv and exists so tests can supply an environment.
type Getenv func(string) string

// Load reads the configuration, applying defaults and rejecting values that
// would make the server unsafe or unable to serve.
func Load(getenv Getenv) (*Config, error) {
	cfg := &Config{
		Listen:                  stringOr(getenv, "RELAY_LISTEN", ":8443"),
		Token:                   getenv("RELAY_TOKEN"),
		TLSCert:                 getenv("RELAY_TLS_CERT"),
		TLSKey:                  getenv("RELAY_TLS_KEY"),
		LogLevel:                strings.ToLower(stringOr(getenv, "RELAY_LOG_LEVEL", "info")),
		MaxConcurrentStreams:    8,
		MaxStreamBytes:          0,
		RateLimitBPS:            0,
		StreamRendezvousTimeout: 30 * time.Second,
		StreamIdleTimeout:       60 * time.Second,
		PairRatePerMin:          5,
	}

	var err error
	if cfg.MaxConcurrentStreams, err = intOr(getenv, "RELAY_MAX_CONCURRENT_STREAMS", cfg.MaxConcurrentStreams); err != nil {
		return nil, err
	}
	if cfg.MaxStreamBytes, err = int64Or(getenv, "RELAY_MAX_STREAM_BYTES", cfg.MaxStreamBytes); err != nil {
		return nil, err
	}
	if cfg.RateLimitBPS, err = int64Or(getenv, "RELAY_RATE_LIMIT_BPS", cfg.RateLimitBPS); err != nil {
		return nil, err
	}
	if cfg.PairRatePerMin, err = intOr(getenv, "RELAY_PAIR_RATE_PER_MIN", cfg.PairRatePerMin); err != nil {
		return nil, err
	}
	if cfg.StreamRendezvousTimeout, err = durationOr(getenv, "RELAY_STREAM_RENDEZVOUS_TIMEOUT", cfg.StreamRendezvousTimeout); err != nil {
		return nil, err
	}
	if cfg.StreamIdleTimeout, err = durationOr(getenv, "RELAY_STREAM_IDLE_TIMEOUT", cfg.StreamIdleTimeout); err != nil {
		return nil, err
	}

	if err := cfg.validate(); err != nil {
		return nil, err
	}
	return cfg, nil
}

func (c *Config) validate() error {
	if c.Token == "" {
		return errors.New("RELAY_TOKEN is required")
	}
	if len(c.Token) < MinTokenLength {
		return fmt.Errorf("RELAY_TOKEN must be at least %d characters, got %d", MinTokenLength, len(c.Token))
	}
	// Half a TLS config is always a mistake, and silently falling back to
	// plaintext would be the worst possible way to resolve it.
	if (c.TLSCert == "") != (c.TLSKey == "") {
		return errors.New("RELAY_TLS_CERT and RELAY_TLS_KEY must be set together")
	}
	if c.MaxConcurrentStreams < 1 {
		return errors.New("RELAY_MAX_CONCURRENT_STREAMS must be at least 1")
	}
	if c.MaxConcurrentStreams > MaxConcurrentStreamsCap {
		return fmt.Errorf("RELAY_MAX_CONCURRENT_STREAMS must not exceed %d", MaxConcurrentStreamsCap)
	}
	if c.MaxStreamBytes < 0 {
		return errors.New("RELAY_MAX_STREAM_BYTES must not be negative")
	}
	if c.RateLimitBPS < 0 {
		return errors.New("RELAY_RATE_LIMIT_BPS must not be negative")
	}
	if c.PairRatePerMin < 1 {
		return errors.New("RELAY_PAIR_RATE_PER_MIN must be at least 1")
	}
	if c.StreamRendezvousTimeout <= 0 {
		return errors.New("RELAY_STREAM_RENDEZVOUS_TIMEOUT must be positive")
	}
	if c.StreamIdleTimeout <= 0 {
		return errors.New("RELAY_STREAM_IDLE_TIMEOUT must be positive")
	}
	switch c.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		return fmt.Errorf("RELAY_LOG_LEVEL must be one of debug, info, warn, error, got %q", c.LogLevel)
	}
	return nil
}

func stringOr(getenv Getenv, key, fallback string) string {
	if v := strings.TrimSpace(getenv(key)); v != "" {
		return v
	}
	return fallback
}

func intOr(getenv Getenv, key string, fallback int) (int, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return v, nil
}

func int64Or(getenv Getenv, key string, fallback int64) (int64, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	v, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return v, nil
}

func durationOr(getenv Getenv, key string, fallback time.Duration) (time.Duration, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	v, err := time.ParseDuration(raw)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return v, nil
}
