// Package metrics exposes Prometheus counters and gauges for relayd.
//
// Labels stay low-cardinality on purpose: never attach deviceId, IP, or stream
// ids. Operators scrape /metrics from loopback; the public reverse proxy should
// not forward that path.
package metrics

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Collector holds the process-wide series relayd exports.
type Collector struct {
	registry prometheus.Registerer
	gatherer prometheus.Gatherer

	authFailures    *prometheus.CounterVec
	errors          *prometheus.CounterVec
	streamsCreated  prometheus.Counter
	bytesRelayed    prometheus.Counter
	pairRateLimited prometheus.Counter
}

// Options wires live gauges that read current process state.
type Options struct {
	Version      string
	SessionCount func() float64
	StreamCount  func() float64
}

// New registers the standard relayd series on reg. Pass nil to use the
// process-wide default registerer (convenient for the binary; tests pass a
// private registry).
func New(reg prometheus.Registerer, opts Options) *Collector {
	if reg == nil {
		reg = prometheus.DefaultRegisterer
	}
	gatherer, ok := reg.(prometheus.Gatherer)
	if !ok {
		panic("metrics: registerer must implement prometheus.Gatherer")
	}

	c := &Collector{
		registry: reg,
		gatherer: gatherer,
		authFailures: prometheus.NewCounterVec(prometheus.CounterOpts{
			Name: "relayd_auth_failures_total",
			Help: "Admission failures, by reason (token or identity).",
		}, []string{"reason"}),
		errors: prometheus.NewCounterVec(prometheus.CounterOpts{
			Name: "relayd_errors_total",
			Help: "Protocol and transport errors, by code.",
		}, []string{"code"}),
		streamsCreated: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "relayd_streams_created_total",
			Help: "Streams allocated on the signaling plane.",
		}),
		bytesRelayed: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "relayd_bytes_relayed_total",
			Help: "Payload bytes successfully copied from sender to receiver.",
		}),
		pairRateLimited: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "relayd_pair_rate_limited_total",
			Help: "Pairing relay messages rejected by the per-device rate limit.",
		}),
	}

	buildInfo := prometheus.NewGaugeVec(prometheus.GaugeOpts{
		Name: "relayd_build_info",
		Help: "Build information; value is always 1.",
	}, []string{"version"})
	sessions := prometheus.NewGaugeFunc(prometheus.GaugeOpts{
		Name: "relayd_signal_sessions",
		Help: "Authenticated signaling sessions currently connected.",
	}, opts.SessionCount)
	streams := prometheus.NewGaugeFunc(prometheus.GaugeOpts{
		Name: "relayd_streams_active",
		Help: "Streams currently allocated in the registry.",
	}, opts.StreamCount)

	reg.MustRegister(
		buildInfo,
		sessions,
		streams,
		c.authFailures,
		c.errors,
		c.streamsCreated,
		c.bytesRelayed,
		c.pairRateLimited,
	)
	buildInfo.WithLabelValues(opts.Version).Set(1)
	return c
}

// Handler serves the Prometheus text exposition format.
func (c *Collector) Handler() http.Handler {
	return promhttp.HandlerFor(c.gatherer, promhttp.HandlerOpts{})
}

// AuthFailure increments the admission-failure counter.
func (c *Collector) AuthFailure(reason string) {
	if c == nil {
		return
	}
	c.authFailures.WithLabelValues(reason).Inc()
}

// Error increments the protocol-error counter.
func (c *Collector) Error(code string) {
	if c == nil {
		return
	}
	c.errors.WithLabelValues(code).Inc()
}

// StreamCreated increments the stream allocation counter.
func (c *Collector) StreamCreated() {
	if c == nil {
		return
	}
	c.streamsCreated.Inc()
}

// BytesRelayed adds n to the successful byte counter.
func (c *Collector) BytesRelayed(n int64) {
	if c == nil || n <= 0 {
		return
	}
	c.bytesRelayed.Add(float64(n))
}

// PairRateLimited increments the pairing throttle counter.
func (c *Collector) PairRateLimited() {
	if c == nil {
		return
	}
	c.pairRateLimited.Inc()
}
