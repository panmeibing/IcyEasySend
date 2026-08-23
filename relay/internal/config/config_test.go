package config

import (
	"strings"
	"testing"
	"time"
)

func env(pairs map[string]string) Getenv {
	return func(key string) string { return pairs[key] }
}

const validToken = "0123456789abcdef0123456789abcdef"

func TestLoadAppliesDefaults(t *testing.T) {
	cfg, err := Load(env(map[string]string{"RELAY_TOKEN": validToken}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if cfg.Listen != ":8443" {
		t.Errorf("Listen = %q, want :8443", cfg.Listen)
	}
	if cfg.MaxConcurrentStreams != 8 {
		t.Errorf("MaxConcurrentStreams = %d, want 8", cfg.MaxConcurrentStreams)
	}
	if cfg.StreamRendezvousTimeout != 30*time.Second {
		t.Errorf("StreamRendezvousTimeout = %v, want 30s", cfg.StreamRendezvousTimeout)
	}
	if cfg.StreamIdleTimeout != 60*time.Second {
		t.Errorf("StreamIdleTimeout = %v, want 60s", cfg.StreamIdleTimeout)
	}
	if cfg.PairRatePerMin != 5 {
		t.Errorf("PairRatePerMin = %d, want 5", cfg.PairRatePerMin)
	}
	if cfg.MaxStreamBytes != 0 || cfg.RateLimitBPS != 0 {
		t.Error("byte and rate caps should default to unlimited")
	}
	if cfg.TLSEnabled() {
		t.Error("TLS should be off by default so the server can run behind a proxy")
	}
}

func TestLoadOverridesEveryKnob(t *testing.T) {
	cfg, err := Load(env(map[string]string{
		"RELAY_TOKEN":                     validToken,
		"RELAY_LISTEN":                    "127.0.0.1:9000",
		"RELAY_MAX_CONCURRENT_STREAMS":    "3",
		"RELAY_MAX_STREAM_BYTES":          "1048576",
		"RELAY_RATE_LIMIT_BPS":            "2048",
		"RELAY_PAIR_RATE_PER_MIN":         "9",
		"RELAY_STREAM_RENDEZVOUS_TIMEOUT": "5s",
		"RELAY_STREAM_IDLE_TIMEOUT":       "7s",
		"RELAY_LOG_LEVEL":                 "DEBUG",
	}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if cfg.Listen != "127.0.0.1:9000" || cfg.MaxConcurrentStreams != 3 {
		t.Errorf("unexpected config: %+v", cfg)
	}
	if cfg.MaxStreamBytes != 1048576 || cfg.RateLimitBPS != 2048 || cfg.PairRatePerMin != 9 {
		t.Errorf("unexpected limits: %+v", cfg)
	}
	if cfg.StreamRendezvousTimeout != 5*time.Second || cfg.StreamIdleTimeout != 7*time.Second {
		t.Errorf("unexpected timeouts: %+v", cfg)
	}
	if cfg.LogLevel != "debug" {
		t.Errorf("LogLevel = %q, want lowercased debug", cfg.LogLevel)
	}
}

func TestBlankValuesFallBackToDefaults(t *testing.T) {
	// Whitespace-only variables come from hand-edited compose files and unset
	// shell expansions; treating them as absent is friendlier than failing.
	cfg, err := Load(env(map[string]string{
		"RELAY_TOKEN":               validToken,
		"RELAY_LISTEN":              "   ",
		"RELAY_STREAM_IDLE_TIMEOUT": "",
	}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cfg.Listen != ":8443" || cfg.StreamIdleTimeout != 60*time.Second {
		t.Errorf("blank values did not fall back: %+v", cfg)
	}
}

func TestLoadRejectsBadInput(t *testing.T) {
	short := strings.Repeat("a", MinTokenLength-1)

	cases := map[string]map[string]string{
		"missing token":     {},
		"short token":       {"RELAY_TOKEN": short},
		"cert without key":  {"RELAY_TOKEN": validToken, "RELAY_TLS_CERT": "/tmp/c.pem"},
		"key without cert":  {"RELAY_TOKEN": validToken, "RELAY_TLS_KEY": "/tmp/k.pem"},
		"zero streams":      {"RELAY_TOKEN": validToken, "RELAY_MAX_CONCURRENT_STREAMS": "0"},
		"negative bytes":    {"RELAY_TOKEN": validToken, "RELAY_MAX_STREAM_BYTES": "-1"},
		"negative bps":      {"RELAY_TOKEN": validToken, "RELAY_RATE_LIMIT_BPS": "-1"},
		"zero pair rate":    {"RELAY_TOKEN": validToken, "RELAY_PAIR_RATE_PER_MIN": "0"},
		"zero rendezvous":   {"RELAY_TOKEN": validToken, "RELAY_STREAM_RENDEZVOUS_TIMEOUT": "0s"},
		"zero idle":         {"RELAY_TOKEN": validToken, "RELAY_STREAM_IDLE_TIMEOUT": "0s"},
		"unknown log level": {"RELAY_TOKEN": validToken, "RELAY_LOG_LEVEL": "verbose"},
		"non-numeric int":   {"RELAY_TOKEN": validToken, "RELAY_MAX_CONCURRENT_STREAMS": "many"},
		"bad duration":      {"RELAY_TOKEN": validToken, "RELAY_STREAM_IDLE_TIMEOUT": "soon"},
	}

	for name, vars := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := Load(env(vars)); err == nil {
				t.Fatal("expected an error, got none")
			}
		})
	}
}

func TestTLSEnabledRequiresBothFiles(t *testing.T) {
	cfg, err := Load(env(map[string]string{
		"RELAY_TOKEN":    validToken,
		"RELAY_TLS_CERT": "/tmp/cert.pem",
		"RELAY_TLS_KEY":  "/tmp/key.pem",
	}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if !cfg.TLSEnabled() {
		t.Error("TLSEnabled should be true when both cert and key are set")
	}
}
