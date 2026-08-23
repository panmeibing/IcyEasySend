// Package limit holds the rate limiters that keep one device from consuming
// the whole server.
package limit

import (
	"context"
	"io"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// PairLimiter throttles pairing requests per device.
//
// Pairing messages are the one kind the relay forwards without requiring a
// mutual subscription, because two devices that have never met cannot
// subscribe to each other yet. That openness is also a harassment vector, so
// it is paid for with a hard per-device rate.
type PairLimiter struct {
	mu       sync.Mutex
	limiters map[string]*entry
	perMin   int
	now      func() time.Time
}

type entry struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// NewPairLimiter allows perMin requests per minute per device, with a full
// burst so a user pairing several devices in a row is not made to wait.
func NewPairLimiter(perMin int) *PairLimiter {
	return &PairLimiter{
		limiters: make(map[string]*entry),
		perMin:   perMin,
		now:      time.Now,
	}
}

// Allow reports whether deviceID may send one more pairing request now.
func (p *PairLimiter) Allow(deviceID string) bool {
	p.mu.Lock()
	defer p.mu.Unlock()

	e, ok := p.limiters[deviceID]
	if !ok {
		e = &entry{
			limiter: rate.NewLimiter(rate.Every(time.Minute/time.Duration(p.perMin)), p.perMin),
		}
		p.limiters[deviceID] = e
	}
	e.lastSeen = p.now()
	return e.limiter.Allow()
}

// Sweep forgets devices idle for longer than maxIdle.
//
// Entries are keyed by device id, so without this the map would grow for the
// lifetime of the process.
func (p *PairLimiter) Sweep(maxIdle time.Duration) int {
	cutoff := p.now().Add(-maxIdle)

	p.mu.Lock()
	defer p.mu.Unlock()

	removed := 0
	for id, e := range p.limiters {
		if e.lastSeen.Before(cutoff) {
			delete(p.limiters, id)
			removed++
		}
	}
	return removed
}

// Len reports how many devices are being tracked.
func (p *PairLimiter) Len() int {
	p.mu.Lock()
	defer p.mu.Unlock()
	return len(p.limiters)
}

// NewBandwidthReader caps a stream to bps bytes per second.
//
// Returns the reader unchanged when bps is zero, which is the default: on a
// self-hosted server the operator's own devices are the only users, and
// throttling them by default would just make transfers slower for no reason.
// Prefer BandwidthPool when multiple streams of the same device must share one
// budget; this helper is for single-stream cases and tests.
func NewBandwidthReader(r io.Reader, bps int64) io.Reader {
	if bps <= 0 {
		return r
	}
	return &bandwidthReader{
		src:     r,
		limiter: newBandwidthLimiter(bps),
	}
}

// BandwidthPool shares one bytes-per-second budget across every stream of a
// device. Without sharing, a client could open N concurrent streams and get
// N× the configured rate.
type BandwidthPool struct {
	mu       sync.Mutex
	limiters map[string]*bwEntry
	bps      int64
	now      func() time.Time
}

type bwEntry struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// NewBandwidthPool builds a pool. A non-positive bps disables throttling.
func NewBandwidthPool(bps int64) *BandwidthPool {
	return &BandwidthPool{
		limiters: make(map[string]*bwEntry),
		bps:      bps,
		now:      time.Now,
	}
}

// Wrap returns a reader that draws from deviceID's shared budget.
func (p *BandwidthPool) Wrap(deviceID string, r io.Reader) io.Reader {
	if p == nil || p.bps <= 0 {
		return r
	}

	p.mu.Lock()
	e, ok := p.limiters[deviceID]
	if !ok {
		e = &bwEntry{limiter: newBandwidthLimiter(p.bps)}
		p.limiters[deviceID] = e
	}
	e.lastSeen = p.now()
	limiter := e.limiter
	p.mu.Unlock()

	touch := func() {
		p.mu.Lock()
		if entry, ok := p.limiters[deviceID]; ok {
			entry.lastSeen = p.now()
		}
		p.mu.Unlock()
	}
	return &bandwidthReader{src: r, limiter: limiter, touch: touch}
}

// Sweep forgets devices idle for longer than maxIdle.
func (p *BandwidthPool) Sweep(maxIdle time.Duration) int {
	if p == nil {
		return 0
	}
	cutoff := p.now().Add(-maxIdle)

	p.mu.Lock()
	defer p.mu.Unlock()

	removed := 0
	for id, e := range p.limiters {
		if e.lastSeen.Before(cutoff) {
			delete(p.limiters, id)
			removed++
		}
	}
	return removed
}

// Len reports how many devices are being tracked.
func (p *BandwidthPool) Len() int {
	if p == nil {
		return 0
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	return len(p.limiters)
}

func newBandwidthLimiter(bps int64) *rate.Limiter {
	// A one-second burst keeps throughput smooth without letting a client
	// bank capacity across a long idle period.
	return rate.NewLimiter(rate.Limit(bps), int(min(bps, 1<<20)))
}

type bandwidthReader struct {
	src     io.Reader
	limiter *rate.Limiter
	touch   func()
}

func (b *bandwidthReader) Read(p []byte) (int, error) {
	// Never ask for more than the burst, or WaitN would fail outright.
	if burst := b.limiter.Burst(); len(p) > burst {
		p = p[:burst]
	}
	n, err := b.src.Read(p)
	if n > 0 {
		if b.touch != nil {
			b.touch()
		}
		if waitErr := b.limiter.WaitN(context.Background(), n); waitErr != nil && err == nil {
			err = waitErr
		}
	}
	return n, err
}
