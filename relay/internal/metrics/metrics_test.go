package metrics

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
)

func TestCollectorExposesExpectedSeries(t *testing.T) {
	reg := prometheus.NewRegistry()
	c := New(reg, Options{
		Version:      "test",
		SessionCount: func() float64 { return 2 },
		StreamCount:  func() float64 { return 1 },
	})

	c.AuthFailure("token")
	c.AuthFailure("identity")
	c.Error("peer_offline")
	c.StreamCreated()
	c.BytesRelayed(42)
	c.PairRateLimited()

	resp := httptest.NewRecorder()
	c.Handler().ServeHTTP(resp, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	if resp.Code != http.StatusOK {
		t.Fatalf("status = %d", resp.Code)
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("ReadAll: %v", err)
	}
	text := string(body)

	for _, needle := range []string{
		`relayd_build_info{version="test"} 1`,
		`relayd_signal_sessions 2`,
		`relayd_streams_active 1`,
		`relayd_auth_failures_total{reason="token"} 1`,
		`relayd_auth_failures_total{reason="identity"} 1`,
		`relayd_errors_total{code="peer_offline"} 1`,
		`relayd_streams_created_total 1`,
		`relayd_bytes_relayed_total 42`,
		`relayd_pair_rate_limited_total 1`,
	} {
		if !strings.Contains(text, needle) {
			t.Errorf("metrics body missing %q\n%s", needle, text)
		}
	}
}
