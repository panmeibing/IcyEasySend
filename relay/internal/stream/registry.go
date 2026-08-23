// Package stream implements the data plane: allocating stream capabilities on
// the signaling plane and joining the two HTTP requests that carry the bytes.
//
// The server never buffers a file. A stream is an io.Pipe with one HTTP
// request writing into it and another reading out, which also means flow
// control is free: if the receiver stops reading, the pipe stops accepting
// writes and TCP back-pressure reaches the sender on its own.
package stream

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io"
	"sync"
	"sync/atomic"
	"time"

	"github.com/icy-easy-send/relay/internal/protocol"
)

// IDBytes is the size of a stream id. At 256 bits the id is itself the
// capability that authorizes attaching to the stream.
const IDBytes = 32

var (
	// ErrTooManyStreams means the device is at its concurrent stream limit.
	ErrTooManyStreams = errors.New(protocol.CodeTooManyStreams)
	// ErrNotFound means the id is unknown or already finished.
	ErrNotFound = errors.New(protocol.CodeStreamNotFound)
	// ErrForbidden means the caller is not one of the stream's two endpoints.
	ErrForbidden = errors.New(protocol.CodeStreamForbidden)
	// ErrAlreadyAttached means that end of the stream is already in use.
	ErrAlreadyAttached = errors.New("endpoint already attached")
	// ErrPeerNotAttached means the other end did not arrive in time.
	ErrPeerNotAttached = errors.New(protocol.CodePeerNotAttached)
)

// Stream is one file's worth of bytes in flight between two devices.
type Stream struct {
	ID        string
	Sender    string
	Receiver  string
	ExpiresAt time.Time

	// owner is the device charged for this stream's quota slot.
	owner string

	reader *io.PipeReader
	writer *io.PipeWriter

	senderAttached   atomic.Bool
	receiverAttached atomic.Bool

	senderReady   chan struct{}
	receiverReady chan struct{}

	closeOnce sync.Once
}

func newStream(id, owner, sender, receiver string, expiresAt time.Time) *Stream {
	reader, writer := io.Pipe()
	return &Stream{
		ID:            id,
		Sender:        sender,
		Receiver:      receiver,
		ExpiresAt:     expiresAt,
		owner:         owner,
		reader:        reader,
		writer:        writer,
		senderReady:   make(chan struct{}),
		receiverReady: make(chan struct{}),
	}
}

// AttachSender claims the writing end and blocks until the receiver arrives.
func (s *Stream) AttachSender(ctx context.Context, timeout time.Duration) (*io.PipeWriter, error) {
	if !s.senderAttached.CompareAndSwap(false, true) {
		return nil, ErrAlreadyAttached
	}
	close(s.senderReady)
	if err := waitFor(ctx, s.receiverReady, timeout); err != nil {
		return nil, err
	}
	return s.writer, nil
}

// AttachReceiver claims the reading end and blocks until the sender arrives.
func (s *Stream) AttachReceiver(ctx context.Context, timeout time.Duration) (*io.PipeReader, error) {
	if !s.receiverAttached.CompareAndSwap(false, true) {
		return nil, ErrAlreadyAttached
	}
	close(s.receiverReady)
	if err := waitFor(ctx, s.senderReady, timeout); err != nil {
		return nil, err
	}
	return s.reader, nil
}

// Role reports whether deviceID is this stream's sender or receiver.
func (s *Stream) Role(deviceID string) (string, error) {
	switch deviceID {
	case s.Sender:
		return protocol.RoleSender, nil
	case s.Receiver:
		return protocol.RoleReceiver, nil
	default:
		return "", ErrForbidden
	}
}

// Close tears both ends down, unblocking whichever side is still waiting.
//
// Both halves of the pipe are closed because either one may be blocked: the
// writer when the receiver hung up, the reader when the sender did. A read
// racing with Close therefore surfaces either err or io.ErrClosedPipe; what
// matters is that it never looks like a clean end of file, so a truncated
// transfer cannot be mistaken for a complete one.
func (s *Stream) Close(err error) {
	s.closeOnce.Do(func() {
		s.writer.CloseWithError(err)
		s.reader.CloseWithError(err)
	})
}

func waitFor(ctx context.Context, ready <-chan struct{}, timeout time.Duration) error {
	timer := time.NewTimer(timeout)
	defer timer.Stop()

	select {
	case <-ready:
		return nil
	case <-timer.C:
		return ErrPeerNotAttached
	case <-ctx.Done():
		return ctx.Err()
	}
}

// Registry tracks live streams and enforces the per-device concurrency cap.
type Registry struct {
	mu        sync.RWMutex
	streams   map[string]*Stream
	perDevice map[string]int

	maxPerDevice int
	ttl          time.Duration
	now          func() time.Time
}

// NewRegistry creates a registry where each device may hold maxPerDevice
// streams at once and an unattached stream expires after ttl.
func NewRegistry(maxPerDevice int, ttl time.Duration) *Registry {
	return &Registry{
		streams:      make(map[string]*Stream),
		perDevice:    make(map[string]int),
		maxPerDevice: maxPerDevice,
		ttl:          ttl,
		now:          time.Now,
	}
}

// Create allocates a stream bound to exactly these two devices.
//
// The quota is charged to owner, the device that asked for the stream, so one
// device cannot exhaust the server by requesting streams towards many peers.
func (r *Registry) Create(owner, sender, receiver string) (*Stream, error) {
	id, err := newID()
	if err != nil {
		return nil, err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	if r.perDevice[owner] >= r.maxPerDevice {
		return nil, ErrTooManyStreams
	}

	s := newStream(id, owner, sender, receiver, r.now().Add(r.ttl))
	r.streams[id] = s
	r.perDevice[owner]++
	return s, nil
}

// Get looks up a stream by id.
func (r *Registry) Get(id string) (*Stream, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	s, ok := r.streams[id]
	if !ok {
		return nil, ErrNotFound
	}
	return s, nil
}

// Release removes a stream and refunds its owner's quota. Safe to call twice.
func (r *Registry) Release(s *Stream) {
	r.mu.Lock()
	if _, ok := r.streams[s.ID]; !ok {
		r.mu.Unlock()
		return
	}
	delete(r.streams, s.ID)
	if r.perDevice[s.owner]--; r.perDevice[s.owner] <= 0 {
		delete(r.perDevice, s.owner)
	}
	r.mu.Unlock()

	s.Close(ErrNotFound)
}

// Sweep drops streams that expired before either end attached.
//
// Without it a client that asks for streams and never uses them would leak
// both memory and quota.
func (r *Registry) Sweep() int {
	now := r.now()

	r.mu.Lock()
	var stale []*Stream
	for id, s := range r.streams {
		if now.Before(s.ExpiresAt) || s.senderAttached.Load() || s.receiverAttached.Load() {
			continue
		}
		stale = append(stale, s)
		delete(r.streams, id)
		if r.perDevice[s.owner]--; r.perDevice[s.owner] <= 0 {
			delete(r.perDevice, s.owner)
		}
	}
	r.mu.Unlock()

	for _, s := range stale {
		s.Close(ErrNotFound)
	}
	return len(stale)
}

// ReleaseDevice drops streams owned by a device that disconnected from the
// signaling plane.
//
// Streams that already have both HTTP endpoints attached are left running on
// the data plane until their handler finishes. Killing an in-flight transfer
// because the WebSocket dropped would break long files on flaky networks even
// though the POST/GET connections are independent.
func (r *Registry) ReleaseDevice(deviceID string) {
	r.mu.Lock()
	var owned []*Stream
	released := 0
	for id, s := range r.streams {
		if s.owner != deviceID {
			continue
		}
		if s.senderAttached.Load() && s.receiverAttached.Load() {
			continue
		}
		owned = append(owned, s)
		delete(r.streams, id)
		released++
	}
	if released > 0 {
		r.perDevice[deviceID] -= released
		if r.perDevice[deviceID] <= 0 {
			delete(r.perDevice, deviceID)
		}
	}
	r.mu.Unlock()

	for _, s := range owned {
		s.Close(ErrNotFound)
	}
}

// Len reports how many streams are currently allocated.
func (r *Registry) Len() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return len(r.streams)
}

func newID() (string, error) {
	raw := make([]byte, IDBytes)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return hex.EncodeToString(raw), nil
}
