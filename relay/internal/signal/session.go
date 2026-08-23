package signal

import (
	"context"
	"crypto/ed25519"
	"encoding/json"
	"sync"
	"time"

	"github.com/coder/websocket"

	"github.com/icy-easy-send/relay/internal/protocol"
)

// outboundBuffer is how many messages may queue for one device before it is
// considered unable to keep up.
//
// Signaling messages are small and infrequent; a client that lets this many
// pile up is wedged, and blocking on it would stall whichever other device is
// trying to reach it.
const outboundBuffer = 32

// Session is one authenticated device's WebSocket connection.
type Session struct {
	DeviceID  string
	PublicKey ed25519.PublicKey
	SessionID string

	conn   *websocket.Conn
	out    chan []byte
	cancel context.CancelFunc

	closeOnce sync.Once
	closed    chan struct{}
}

func newSession(deviceID, sessionID string, publicKey ed25519.PublicKey, conn *websocket.Conn, cancel context.CancelFunc) *Session {
	return &Session{
		DeviceID:  deviceID,
		PublicKey: publicKey,
		SessionID: sessionID,
		conn:      conn,
		out:       make(chan []byte, outboundBuffer),
		cancel:    cancel,
		closed:    make(chan struct{}),
	}
}

// Send queues a message for delivery.
//
// It never blocks: a device that cannot drain its queue is disconnected
// instead, so one stalled client cannot slow down the peers talking to it.
func (s *Session) Send(msg any) bool {
	data, err := json.Marshal(msg)
	if err != nil {
		return false
	}

	select {
	case <-s.closed:
		return false
	default:
	}

	select {
	case s.out <- data:
		return true
	default:
		s.Close()
		return false
	}
}

// SendError delivers an error, echoing mid so the client can match it to the
// request that failed.
func (s *Session) SendError(mid, code, message string) {
	envelope := protocol.NewEnvelope(protocol.TypeError, time.Now().Unix())
	envelope.MID = mid
	s.Send(protocol.Error{Envelope: envelope, Code: code, Message: message})
}

// Close stops the session's goroutines. Safe to call repeatedly.
func (s *Session) Close() {
	s.closeOnce.Do(func() {
		close(s.closed)
		s.cancel()
	})
}

// writeLoop is the only goroutine that writes to the socket.
func (s *Session) writeLoop(ctx context.Context, writeTimeout time.Duration) {
	for {
		select {
		case <-ctx.Done():
			return
		case <-s.closed:
			return
		case data := <-s.out:
			writeCtx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := s.conn.Write(writeCtx, websocket.MessageText, data)
			cancel()
			if err != nil {
				s.Close()
				return
			}
		}
	}
}

// pingLoop keeps the connection alive through NATs and idle-reaping proxies,
// and detects a peer that vanished without closing the socket.
func (s *Session) pingLoop(ctx context.Context, interval, timeout time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-s.closed:
			return
		case <-ticker.C:
			pingCtx, cancel := context.WithTimeout(ctx, timeout)
			err := s.conn.Ping(pingCtx)
			cancel()
			if err != nil {
				s.Close()
				return
			}
		}
	}
}
