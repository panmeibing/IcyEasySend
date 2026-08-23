package stream

import (
	"bytes"
	"context"
	"errors"
	"io"
	"sync"
	"testing"
	"time"
)

const (
	alice = "aaaa0000aaaa0000aaaa0000aaaa0000"
	bob   = "bbbb1111bbbb1111bbbb1111bbbb1111"
)

func TestCreateBindsBothEndpoints(t *testing.T) {
	r := NewRegistry(4, time.Minute)

	s, err := r.Create(alice, alice, bob)
	if err != nil {
		t.Fatalf("Create: %v", err)
	}

	if len(s.ID) != IDBytes*2 {
		t.Errorf("stream id length = %d, want %d hex chars", len(s.ID), IDBytes*2)
	}

	if role, err := s.Role(alice); err != nil || role != "sender" {
		t.Errorf("Role(alice) = %q, %v", role, err)
	}
	if role, err := s.Role(bob); err != nil || role != "receiver" {
		t.Errorf("Role(bob) = %q, %v", role, err)
	}
	if _, err := s.Role("cccc"); !errors.Is(err, ErrForbidden) {
		t.Error("a third device must not be an endpoint of this stream")
	}
}

func TestCreateGeneratesUniqueIDs(t *testing.T) {
	r := NewRegistry(100, time.Minute)
	seen := map[string]bool{}

	for i := 0; i < 50; i++ {
		s, err := r.Create(alice, alice, bob)
		if err != nil {
			t.Fatalf("Create: %v", err)
		}
		if seen[s.ID] {
			t.Fatal("stream ids must not repeat")
		}
		seen[s.ID] = true
	}
}

func TestConcurrentStreamLimitIsPerOwner(t *testing.T) {
	r := NewRegistry(2, time.Minute)

	first, _ := r.Create(alice, alice, bob)
	if _, err := r.Create(alice, alice, bob); err != nil {
		t.Fatalf("second stream should fit under the limit: %v", err)
	}
	if _, err := r.Create(alice, alice, bob); !errors.Is(err, ErrTooManyStreams) {
		t.Fatalf("err = %v, want ErrTooManyStreams", err)
	}

	// Another device has its own budget.
	if _, err := r.Create(bob, bob, alice); err != nil {
		t.Fatalf("bob should have his own quota: %v", err)
	}

	// Releasing refunds the slot.
	r.Release(first)
	if _, err := r.Create(alice, alice, bob); err != nil {
		t.Fatalf("quota should be refunded on release: %v", err)
	}
}

func TestGetAndRelease(t *testing.T) {
	r := NewRegistry(4, time.Minute)
	s, _ := r.Create(alice, alice, bob)

	if got, err := r.Get(s.ID); err != nil || got != s {
		t.Fatalf("Get returned %v, %v", got, err)
	}

	r.Release(s)
	if _, err := r.Get(s.ID); !errors.Is(err, ErrNotFound) {
		t.Fatalf("err = %v, want ErrNotFound", err)
	}

	// Releasing twice must not double-refund the quota.
	r.Release(s)
	if r.Len() != 0 {
		t.Errorf("Len = %d, want 0", r.Len())
	}
}

func TestUnknownStreamIsNotFound(t *testing.T) {
	r := NewRegistry(4, time.Minute)

	if _, err := r.Get("does-not-exist"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("err = %v, want ErrNotFound", err)
	}
}

func TestRendezvousJoinsBothEnds(t *testing.T) {
	r := NewRegistry(4, time.Minute)
	s, _ := r.Create(alice, alice, bob)

	payload := bytes.Repeat([]byte("icy"), 20000)
	var received []byte
	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		reader, err := s.AttachReceiver(context.Background(), time.Second)
		if err != nil {
			t.Errorf("AttachReceiver: %v", err)
			return
		}
		received, _ = io.ReadAll(reader)
	}()

	writer, err := s.AttachSender(context.Background(), time.Second)
	if err != nil {
		t.Fatalf("AttachSender: %v", err)
	}
	if _, err := writer.Write(payload); err != nil {
		t.Fatalf("Write: %v", err)
	}
	writer.Close()

	wg.Wait()
	if !bytes.Equal(received, payload) {
		t.Errorf("received %d bytes, sent %d", len(received), len(payload))
	}
}

func TestRendezvousTimesOutWithoutAPeer(t *testing.T) {
	r := NewRegistry(4, time.Minute)
	s, _ := r.Create(alice, alice, bob)

	start := time.Now()
	_, err := s.AttachSender(context.Background(), 50*time.Millisecond)
	if !errors.Is(err, ErrPeerNotAttached) {
		t.Fatalf("err = %v, want ErrPeerNotAttached", err)
	}
	if elapsed := time.Since(start); elapsed > time.Second {
		t.Errorf("waited %v, expected to give up quickly", elapsed)
	}
}

func TestRendezvousHonoursCancellation(t *testing.T) {
	r := NewRegistry(4, time.Minute)
	s, _ := r.Create(alice, alice, bob)

	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		time.Sleep(20 * time.Millisecond)
		cancel()
	}()

	// A client hanging up must free the goroutine immediately rather than
	// holding it for the full rendezvous window.
	if _, err := s.AttachReceiver(ctx, 10*time.Second); !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want context.Canceled", err)
	}
}

func TestEachEndAttachesOnce(t *testing.T) {
	r := NewRegistry(4, time.Minute)
	s, _ := r.Create(alice, alice, bob)

	go func() {
		_, _ = s.AttachReceiver(context.Background(), time.Second)
	}()

	if _, err := s.AttachSender(context.Background(), time.Second); err != nil {
		t.Fatalf("AttachSender: %v", err)
	}
	if _, err := s.AttachSender(context.Background(), time.Second); !errors.Is(err, ErrAlreadyAttached) {
		t.Fatalf("err = %v, want ErrAlreadyAttached", err)
	}
}

func TestSweepReclaimsOnlyExpiredUnattachedStreams(t *testing.T) {
	r := NewRegistry(8, time.Minute)
	now := time.Now()
	r.now = func() time.Time { return now }

	expired, _ := r.Create(alice, alice, bob)
	fresh, _ := r.Create(bob, bob, alice)

	// Move past the first stream's expiry, then keep the second one fresh.
	now = now.Add(2 * time.Minute)
	fresh.ExpiresAt = now.Add(time.Minute)

	if reclaimed := r.Sweep(); reclaimed != 1 {
		t.Fatalf("Sweep reclaimed %d, want 1", reclaimed)
	}
	if _, err := r.Get(expired.ID); !errors.Is(err, ErrNotFound) {
		t.Error("expired stream should be gone")
	}
	if _, err := r.Get(fresh.ID); err != nil {
		t.Error("unexpired stream should survive")
	}
}

func TestSweepSparesAStreamThatIsWaitingForItsPeer(t *testing.T) {
	r := NewRegistry(8, time.Minute)
	now := time.Now()
	r.now = func() time.Time { return now }

	s, _ := r.Create(alice, alice, bob)
	go func() {
		_, _ = s.AttachSender(context.Background(), 5*time.Second)
	}()

	// Wait for the attach to register before advancing the clock.
	waitFor(context.Background(), s.senderReady, time.Second)
	now = now.Add(2 * time.Minute)

	if reclaimed := r.Sweep(); reclaimed != 0 {
		t.Fatalf("Sweep reclaimed %d, want 0: a half-attached stream is still in use", reclaimed)
	}
}

func TestReleaseDeviceDropsEverythingItOwns(t *testing.T) {
	r := NewRegistry(8, time.Minute)
	first, _ := r.Create(alice, alice, bob)
	second, _ := r.Create(alice, alice, bob)
	other, _ := r.Create(bob, bob, alice)

	r.ReleaseDevice(alice)

	if _, err := r.Get(first.ID); !errors.Is(err, ErrNotFound) {
		t.Error("first stream should be gone")
	}
	if _, err := r.Get(second.ID); !errors.Is(err, ErrNotFound) {
		t.Error("second stream should be gone")
	}
	if _, err := r.Get(other.ID); err != nil {
		t.Error("another device's stream must survive")
	}
}

func TestReleaseDevicePreservesFullyAttachedStreams(t *testing.T) {
	r := NewRegistry(8, time.Minute)
	idle, _ := r.Create(alice, alice, bob)
	active, _ := r.Create(alice, alice, bob)

	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		reader, err := active.AttachReceiver(context.Background(), time.Second)
		if err != nil {
			t.Errorf("AttachReceiver: %v", err)
			return
		}
		_, _ = io.ReadAll(reader)
	}()

	writer, err := active.AttachSender(context.Background(), time.Second)
	if err != nil {
		t.Fatalf("AttachSender: %v", err)
	}

	r.ReleaseDevice(alice)

	if _, err := r.Get(idle.ID); !errors.Is(err, ErrNotFound) {
		t.Error("idle stream should be released on disconnect")
	}
	if got, err := r.Get(active.ID); err != nil || got != active {
		t.Fatal("fully attached stream should survive signaling teardown")
	}

	if _, err := writer.Write([]byte("payload")); err != nil {
		t.Fatalf("Write after ReleaseDevice: %v", err)
	}
	writer.Close()
	wg.Wait()

	r.Release(active)
	if r.Len() != 0 {
		t.Errorf("Len = %d, want 0 after transfer completes", r.Len())
	}
}

func TestCloseUnblocksAWaitingReader(t *testing.T) {
	r := NewRegistry(4, time.Minute)
	s, _ := r.Create(alice, alice, bob)

	go func() {
		_, _ = s.AttachSender(context.Background(), time.Second)
	}()
	reader, err := s.AttachReceiver(context.Background(), time.Second)
	if err != nil {
		t.Fatalf("AttachReceiver: %v", err)
	}

	go func() {
		time.Sleep(20 * time.Millisecond)
		s.Close(io.ErrUnexpectedEOF)
	}()

	// An aborted stream must never read as a clean EOF, or the receiver would
	// treat a truncated file as a complete one.
	if _, err := io.ReadAll(reader); err == nil {
		t.Fatal("reading an aborted stream should fail, not end cleanly")
	}
}
