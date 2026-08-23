// Command relayd is a dumb pipe between two devices that cannot reach each
// other directly.
//
// It authenticates who may use it, tells devices when their peers are online,
// forwards opaque messages between them, and joins two HTTP requests into one
// byte stream. It never inspects, buffers or stores file content.
package main

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"os"
	ossignal "os/signal"
	"syscall"
	"time"

	"github.com/icy-easy-send/relay/internal/config"
	"github.com/icy-easy-send/relay/internal/limit"
	"github.com/icy-easy-send/relay/internal/metrics"
	"github.com/icy-easy-send/relay/internal/protocol"
	"github.com/icy-easy-send/relay/internal/signal"
	"github.com/icy-easy-send/relay/internal/stream"
)

// version is stamped at build time with -ldflags "-X main.version=...".
var version = "dev"

const (
	sweepInterval  = 30 * time.Second
	limiterMaxIdle = 10 * time.Minute
	shutdownGrace  = 10 * time.Second
)

func main() {
	if err := run(); err != nil {
		slog.Error("relayd exited", "err", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}

	logger := newLogger(cfg.LogLevel)
	slog.SetDefault(logger)

	hub := signal.NewHub()
	streams := stream.NewRegistry(cfg.MaxConcurrentStreams, cfg.StreamRendezvousTimeout)
	pairLimiter := limit.NewPairLimiter(cfg.PairRatePerMin)
	bandwidth := limit.NewBandwidthPool(cfg.RateLimitBPS)

	collector := metrics.New(nil, metrics.Options{
		Version:      version,
		SessionCount: func() float64 { return float64(hub.Count()) },
		StreamCount:  func() float64 { return float64(streams.Len()) },
	})

	signalServer := signal.NewServer(signal.ServerOptions{
		Hub:         hub,
		Streams:     streams,
		Token:       cfg.Token,
		PairLimiter: pairLimiter,
		Observer:    collector,
		Limits: protocol.Limits{
			MaxConcurrentStreams: cfg.MaxConcurrentStreams,
			MaxStreamBytes:       cfg.MaxStreamBytes,
			MaxMessageBytes:      protocol.MaxMessageBytes,
			PairRatePerMin:       cfg.PairRatePerMin,
		},
		Logger: logger,
	})

	streamHandler := stream.NewHandler(stream.HandlerOptions{
		Registry:          streams,
		Token:             cfg.Token,
		Keys:              hub.PublicKey,
		RendezvousTimeout: cfg.StreamRendezvousTimeout,
		IdleTimeout:       cfg.StreamIdleTimeout,
		MaxStreamBytes:    cfg.MaxStreamBytes,
		Limiter:           bandwidth.Wrap,
		Observer:          collector,
		Logger:            logger,
	})

	mux := http.NewServeMux()
	mux.Handle("/v1/signal", signalServer)
	mux.Handle("/v1/stream/", streamHandler)
	mux.Handle("/metrics", collector.Handler())
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = io.WriteString(w, `{"ok":true,"service":"relayd","version":"`+version+`"}`)
	})

	server := &http.Server{
		Addr:    cfg.Listen,
		Handler: mux,
		// No global read or write timeout: file streams legitimately run for
		// hours. Liveness is enforced per stream by the idle deadline, and per
		// connection by WebSocket pings.
		ReadHeaderTimeout: 15 * time.Second,
		ErrorLog:          slog.NewLogLogger(logger.Handler(), slog.LevelDebug),
	}

	ctx, stop := ossignal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go sweep(ctx, streams, pairLimiter, bandwidth, logger)

	errs := make(chan error, 1)
	go func() {
		logger.Info("relayd listening",
			"addr", cfg.Listen,
			"tls", cfg.TLSEnabled(),
			"version", version,
			"maxConcurrentStreams", cfg.MaxConcurrentStreams,
			"rateLimitBPS", cfg.RateLimitBPS,
		)
		if cfg.TLSEnabled() {
			errs <- server.ListenAndServeTLS(cfg.TLSCert, cfg.TLSKey)
			return
		}
		errs <- server.ListenAndServe()
	}()

	select {
	case err := <-errs:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return err
	case <-ctx.Done():
	}

	logger.Info("shutting down")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownGrace)
	defer cancel()
	return server.Shutdown(shutdownCtx)
}

// sweep reclaims streams that were allocated but never used and rate limiter
// entries for devices that have gone away.
func sweep(
	ctx context.Context,
	streams *stream.Registry,
	pairLimiter *limit.PairLimiter,
	bandwidth *limit.BandwidthPool,
	logger *slog.Logger,
) {
	ticker := time.NewTicker(sweepInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if expired := streams.Sweep(); expired > 0 {
				logger.Debug("reclaimed unattached streams", "count", expired)
			}
			pairLimiter.Sweep(limiterMaxIdle)
			bandwidth.Sweep(limiterMaxIdle)
		}
	}
}

func newLogger(level string) *slog.Logger {
	var l slog.Level
	switch level {
	case "debug":
		l = slog.LevelDebug
	case "warn":
		l = slog.LevelWarn
	case "error":
		l = slog.LevelError
	default:
		l = slog.LevelInfo
	}

	return slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: l}))
}
