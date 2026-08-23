package signal

import (
	"bytes"
	"crypto/ed25519"
	"encoding/base64"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/icy-easy-send/relay/internal/auth"
	"github.com/icy-easy-send/relay/internal/limit"
	"github.com/icy-easy-send/relay/internal/protocol"
	"github.com/icy-easy-send/relay/internal/stream"
)

// TestTransferThroughBothPlanes walks the whole path a file takes: two devices
// authenticate on the signaling plane, one asks for a stream, they exchange
// the id out of band through a relayed message, and the bytes move over HTTP.
//
// The two planes are separate packages with separate tests; this is the one
// place that proves they actually fit together, in particular that a key
// learned during the WebSocket handshake is what authorizes the HTTP request.
func TestTransferThroughBothPlanes(t *testing.T) {
	hub := NewHub()
	streams := stream.NewRegistry(4, time.Minute)

	mux := http.NewServeMux()
	mux.Handle("/v1/signal", NewServer(ServerOptions{
		Hub:          hub,
		Streams:      streams,
		Token:        testToken,
		PairLimiter:  limit.NewPairLimiter(5),
		PingInterval: time.Hour,
	}))
	mux.Handle("/v1/stream/", stream.NewHandler(stream.HandlerOptions{
		Registry:          streams,
		Token:             testToken,
		Keys:              hub.PublicKey,
		RendezvousTimeout: 3 * time.Second,
		IdleTimeout:       3 * time.Second,
	}))

	server := httptest.NewServer(mux)
	defer server.Close()

	h := &harness{
		server:  server,
		hub:     hub,
		streams: streams,
		url:     "ws" + strings.TrimPrefix(server.URL, "http") + "/v1/signal",
	}

	senderPublic, senderPrivate, _ := ed25519.GenerateKey(nil)
	receiverPublic, receiverPrivate, _ := ed25519.GenerateKey(nil)

	sender := h.dialAs(t, senderPublic, senderPrivate, testToken)
	receiver := h.dialAs(t, receiverPublic, receiverPrivate, testToken)

	// The sender allocates a stream towards the receiver.
	sender.write(protocol.StreamCreate{
		Envelope: protocol.NewEnvelope(protocol.TypeStreamCreate, time.Now().Unix()),
		Peer:     receiver.deviceID,
		Role:     protocol.RoleSender,
	})
	var created protocol.StreamCreated
	sender.read(&created)

	// It tells the receiver which stream to pick up. To the server this is an
	// opaque payload; in the real protocol it is the encrypted file.begin.
	sender.write(protocol.Relay{
		Envelope: protocol.NewEnvelope(protocol.TypeRelay, time.Now().Unix()),
		To:       receiver.deviceID,
		Kind:     protocol.KindTransfer,
		Payload:  base64.StdEncoding.EncodeToString([]byte(created.StreamID)),
	})
	var notice protocol.Relay
	receiver.read(&notice)

	announced, err := base64.StdEncoding.DecodeString(notice.Payload)
	if err != nil {
		t.Fatalf("decode payload: %v", err)
	}
	streamID := string(announced)
	if streamID != created.StreamID {
		t.Fatalf("receiver got stream %q, sender created %q", streamID, created.StreamID)
	}

	url := server.URL + "/v1/stream/" + streamID
	payload := bytes.Repeat([]byte("end-to-end"), 10000)

	downloaded := make(chan []byte, 1)
	go func() {
		req, _ := http.NewRequest(http.MethodGet, url, nil)
		req.Header.Set("Authorization", "Bearer "+testToken)
		req.Header.Set("X-Device-Id", receiver.deviceID)
		req.Header.Set("X-Stream-Proof", sign(receiverPrivate, streamID))

		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			downloaded <- nil
			return
		}
		defer resp.Body.Close()
		data, _ := io.ReadAll(resp.Body)
		downloaded <- data
	}()

	req, _ := http.NewRequest(http.MethodPost, url, bytes.NewReader(payload))
	req.Header.Set("Authorization", "Bearer "+testToken)
	req.Header.Set("X-Device-Id", sender.deviceID)
	req.Header.Set("X-Stream-Proof", sign(senderPrivate, streamID))

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("upload: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("upload status = %d", resp.StatusCode)
	}
	if got := <-downloaded; !bytes.Equal(got, payload) {
		t.Fatalf("received %d bytes, sent %d", len(got), len(payload))
	}
}

// TestStreamProofRequiresALiveSignalingSession shows the two planes are linked:
// the data plane trusts a key only while the device holds a WebSocket session.
func TestStreamProofRequiresALiveSignalingSession(t *testing.T) {
	hub := NewHub()
	streams := stream.NewRegistry(4, time.Minute)

	mux := http.NewServeMux()
	mux.Handle("/v1/signal", NewServer(ServerOptions{
		Hub:          hub,
		Streams:      streams,
		Token:        testToken,
		PairLimiter:  limit.NewPairLimiter(5),
		PingInterval: time.Hour,
	}))
	mux.Handle("/v1/stream/", stream.NewHandler(stream.HandlerOptions{
		Registry:          streams,
		Token:             testToken,
		Keys:              hub.PublicKey,
		RendezvousTimeout: 200 * time.Millisecond,
		IdleTimeout:       time.Second,
	}))

	server := httptest.NewServer(mux)
	defer server.Close()

	h := &harness{hub: hub, streams: streams, url: "ws" + strings.TrimPrefix(server.URL, "http") + "/v1/signal"}

	senderPublic, senderPrivate, _ := ed25519.GenerateKey(nil)
	receiver := h.dialWithToken(t, testToken)
	sender := h.dialAs(t, senderPublic, senderPrivate, testToken)

	s, err := streams.Create(sender.deviceID, sender.deviceID, receiver.deviceID)
	if err != nil {
		t.Fatalf("Create: %v", err)
	}

	// The sender goes away. Its key is forgotten with the session, so the
	// capability it was holding is no longer usable by anyone.
	sender.conn.CloseNow()
	waitUntil(t, func() bool { _, ok := hub.PublicKey(sender.deviceID); return !ok })

	req, _ := http.NewRequest(http.MethodPost, server.URL+"/v1/stream/"+s.ID, bytes.NewReader([]byte("x")))
	req.Header.Set("Authorization", "Bearer "+testToken)
	req.Header.Set("X-Device-Id", sender.deviceID)
	req.Header.Set("X-Stream-Proof", sign(senderPrivate, s.ID))

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", resp.StatusCode)
	}
}

func sign(private ed25519.PrivateKey, streamID string) string {
	return base64.StdEncoding.EncodeToString(ed25519.Sign(private, auth.StreamMessage(streamID)))
}

func waitUntil(t *testing.T, condition func() bool) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if condition() {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("condition was not met in time")
}
