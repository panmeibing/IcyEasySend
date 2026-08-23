package limit

import (
	"bytes"
	"io"
	"testing"
	"time"
)

func TestPairLimiterAllowsABurstThenThrottles(t *testing.T) {
	l := NewPairLimiter(3)

	for i := 0; i < 3; i++ {
		if !l.Allow("device-a") {
			t.Fatalf("request %d should be allowed within the burst", i+1)
		}
	}
	if l.Allow("device-a") {
		t.Error("the fourth request should be throttled")
	}
}

func TestPairLimiterIsPerDevice(t *testing.T) {
	l := NewPairLimiter(1)

	if !l.Allow("device-a") || l.Allow("device-a") {
		t.Fatal("device-a should get exactly one request")
	}
	// One noisy device must not silence everyone else.
	if !l.Allow("device-b") {
		t.Error("device-b has its own budget")
	}
}

func TestPairLimiterRefillsOverTime(t *testing.T) {
	l := NewPairLimiter(60)
	now := time.Now()
	l.now = func() time.Time { return now }

	for i := 0; i < 60; i++ {
		l.Allow("device-a")
	}
	if l.Allow("device-a") {
		t.Fatal("burst should be exhausted")
	}

	// At 60 per minute a token appears every second; rate.Limiter reads the
	// real clock, so wait for a real one rather than faking it.
	time.Sleep(1100 * time.Millisecond)
	if !l.Allow("device-a") {
		t.Error("a token should have been refilled")
	}
}

func TestPairLimiterSweepForgetsIdleDevices(t *testing.T) {
	l := NewPairLimiter(5)
	now := time.Now()
	l.now = func() time.Time { return now }

	l.Allow("stale")
	now = now.Add(time.Hour)
	l.Allow("fresh")

	if removed := l.Sweep(10 * time.Minute); removed != 1 {
		t.Fatalf("Sweep removed %d, want 1", removed)
	}
	if l.Len() != 1 {
		t.Errorf("Len = %d, want 1", l.Len())
	}
}

func TestBandwidthReaderIsATransparentPassthroughWhenDisabled(t *testing.T) {
	src := bytes.NewReader([]byte("payload"))
	if got := NewBandwidthReader(src, 0); got != io.Reader(src) {
		t.Error("a zero rate should return the reader unchanged, not wrap it")
	}
}

func TestBandwidthReaderDeliversEveryByte(t *testing.T) {
	payload := bytes.Repeat([]byte("x"), 8192)

	// Throttling must never truncate; it only decides when bytes arrive.
	got, err := io.ReadAll(NewBandwidthReader(bytes.NewReader(payload), 1<<20))
	if err != nil {
		t.Fatalf("ReadAll: %v", err)
	}
	if !bytes.Equal(got, payload) {
		t.Errorf("read %d bytes, want %d", len(got), len(payload))
	}
}

func TestBandwidthReaderSlowsDownToTheConfiguredRate(t *testing.T) {
	const bps = 4096
	payload := bytes.Repeat([]byte("x"), 8192)

	start := time.Now()
	if _, err := io.ReadAll(NewBandwidthReader(bytes.NewReader(payload), bps)); err != nil {
		t.Fatalf("ReadAll: %v", err)
	}

	// Two seconds' worth of data at this rate, minus the initial burst; the
	// assertion stays loose because only the order of magnitude matters.
	if elapsed := time.Since(start); elapsed < 500*time.Millisecond {
		t.Errorf("read finished in %v, expected throttling to slow it down", elapsed)
	}
}

func TestBandwidthPoolIsTransparentWhenDisabled(t *testing.T) {
	src := bytes.NewReader([]byte("payload"))
	pool := NewBandwidthPool(0)
	if got := pool.Wrap("device-a", src); got != io.Reader(src) {
		t.Error("a zero rate should return the reader unchanged")
	}
}

func TestBandwidthPoolSharesBudgetAcrossStreamsOfOneDevice(t *testing.T) {
	const bps = 4096
	payload := bytes.Repeat([]byte("x"), 8192)
	pool := NewBandwidthPool(bps)

	start := time.Now()
	errCh := make(chan error, 2)
	for i := 0; i < 2; i++ {
		go func() {
			_, err := io.ReadAll(pool.Wrap("device-a", bytes.NewReader(payload)))
			errCh <- err
		}()
	}
	for i := 0; i < 2; i++ {
		if err := <-errCh; err != nil {
			t.Fatalf("ReadAll: %v", err)
		}
	}

	// Two streams × 8 KiB at a shared 4 KiB/s budget needs roughly 4s of
	// tokens. Per-stream limiters would finish near 2s; require >2.5s so the
	// shared budget is what actually constrained them.
	if elapsed := time.Since(start); elapsed < 2500*time.Millisecond {
		t.Errorf("parallel reads finished in %v; shared budget should have slowed them", elapsed)
	}
}

func TestBandwidthPoolIsolatesDevices(t *testing.T) {
	const bps = 4096
	payload := bytes.Repeat([]byte("x"), 8192)
	pool := NewBandwidthPool(bps)

	start := time.Now()
	errCh := make(chan error, 2)
	for _, id := range []string{"device-a", "device-b"} {
		go func(deviceID string) {
			_, err := io.ReadAll(pool.Wrap(deviceID, bytes.NewReader(payload)))
			errCh <- err
		}(id)
	}
	for i := 0; i < 2; i++ {
		if err := <-errCh; err != nil {
			t.Fatalf("ReadAll: %v", err)
		}
	}

	// Separate budgets let both devices finish on the single-stream schedule
	// (~2s of data with a 1s burst), well under the shared-pool wall time.
	if elapsed := time.Since(start); elapsed > 3500*time.Millisecond {
		t.Errorf("independent devices took %v; they should not share a budget", elapsed)
	}
}

func TestBandwidthPoolSweepForgetsIdleDevices(t *testing.T) {
	pool := NewBandwidthPool(1024)
	now := time.Now()
	pool.now = func() time.Time { return now }

	_ = pool.Wrap("stale", bytes.NewReader(nil))
	now = now.Add(time.Hour)
	_ = pool.Wrap("fresh", bytes.NewReader(nil))

	if removed := pool.Sweep(10 * time.Minute); removed != 1 {
		t.Fatalf("Sweep removed %d, want 1", removed)
	}
	if pool.Len() != 1 {
		t.Errorf("Len = %d, want 1", pool.Len())
	}
}
