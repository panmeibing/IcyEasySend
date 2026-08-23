package stream

import (
	"bytes"
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/icy-easy-send/relay/internal/auth"
	"github.com/icy-easy-send/relay/internal/protocol"
)

const testToken = "0123456789abcdef0123456789abcdef"

type identity struct {
	deviceID string
	public   ed25519.PublicKey
	private  ed25519.PrivateKey
}

func newIdentity(t *testing.T) identity {
	t.Helper()
	public, private, err := ed25519.GenerateKey(nil)
	if err != nil {
		t.Fatalf("GenerateKey: %v", err)
	}
	return identity{auth.DeviceIDFromPublicKey(public), public, private}
}

func (i identity) proof(streamID string) string {
	return base64.StdEncoding.EncodeToString(ed25519.Sign(i.private, auth.StreamMessage(streamID)))
}

// testServer wires a registry and handler with the given identities known.
func testServer(t *testing.T, registry *Registry, known ...identity) *httptest.Server {
	t.Helper()

	keys := map[string]ed25519.PublicKey{}
	for _, id := range known {
		keys[id.deviceID] = id.public
	}

	handler := NewHandler(HandlerOptions{
		Registry: registry,
		Token:    testToken,
		Keys: func(deviceID string) (ed25519.PublicKey, bool) {
			key, ok := keys[deviceID]
			return key, ok
		},
		RendezvousTimeout: 2 * time.Second,
		IdleTimeout:       2 * time.Second,
	})

	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	return server
}

func request(t *testing.T, method, url string, id identity, streamID string, body io.Reader) *http.Request {
	t.Helper()
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		t.Fatalf("NewRequest: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+testToken)
	req.Header.Set("X-Device-Id", id.deviceID)
	req.Header.Set("X-Stream-Proof", id.proof(streamID))
	return req
}

func decodeError(t *testing.T, resp *http.Response) string {
	t.Helper()
	var body struct {
		Code string `json:"code"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatalf("decode error body: %v", err)
	}
	return body.Code
}

func TestStreamRelaysBytesEndToEnd(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender, receiver)

	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)
	url := server.URL + "/v1/stream/" + s.ID
	payload := bytes.Repeat([]byte("relayed-bytes"), 5000)

	type download struct {
		data []byte
		err  error
	}
	downloaded := make(chan download, 1)
	go func() {
		resp, err := http.DefaultClient.Do(request(t, http.MethodGet, url, receiver, s.ID, nil))
		if err != nil {
			downloaded <- download{err: err}
			return
		}
		defer resp.Body.Close()
		data, err := io.ReadAll(resp.Body)
		downloaded <- download{data: data, err: err}
	}()

	resp, err := http.DefaultClient.Do(request(t, http.MethodPost, url, sender, s.ID, bytes.NewReader(payload)))
	if err != nil {
		t.Fatalf("upload: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("upload status = %d", resp.StatusCode)
	}
	var summary struct {
		OK    bool  `json:"ok"`
		Bytes int64 `json:"bytes"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&summary); err != nil {
		t.Fatalf("decode summary: %v", err)
	}
	if !summary.OK || summary.Bytes != int64(len(payload)) {
		t.Errorf("summary = %+v, want %d bytes", summary, len(payload))
	}

	got := <-downloaded
	// The error matters as much as the bytes. Tearing the stream down as soon
	// as the upload finished used to abort the response after every byte had
	// already arrived, which a comparison of the payloads alone cannot see.
	if got.err != nil {
		t.Errorf("download ended with %v, want a clean end of body", got.err)
	}
	if !bytes.Equal(got.data, payload) {
		t.Errorf("downloaded %d bytes, uploaded %d", len(got.data), len(payload))
	}

	// The stream is single use; both sides released it when they finished.
	if registry.Len() != 0 {
		t.Errorf("registry still holds %d streams", registry.Len())
	}
}

func TestStreamRejectsAWrongToken(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender, receiver)
	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)

	req := request(t, http.MethodPost, server.URL+"/v1/stream/"+s.ID, sender, s.ID, nil)
	req.Header.Set("Authorization", "Bearer wrong-token")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", resp.StatusCode)
	}
	if code := decodeError(t, resp); code != protocol.CodeUnauthorized {
		t.Errorf("code = %q", code)
	}
}

func TestStreamRejectsAnUnknownDevice(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	stranger := newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	// The stranger never authenticated on the signaling plane, so the server
	// holds no key for it and cannot check any proof it offers.
	server := testServer(t, registry, sender, receiver)
	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)

	resp, err := http.DefaultClient.Do(request(t, http.MethodPost, server.URL+"/v1/stream/"+s.ID, stranger, s.ID, nil))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if code := decodeError(t, resp); code != protocol.CodeBadIdentity {
		t.Errorf("code = %q, want bad_identity", code)
	}
}

func TestStreamRejectsAForgedProof(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender, receiver)
	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)

	req := request(t, http.MethodPost, server.URL+"/v1/stream/"+s.ID, sender, s.ID, nil)
	// A proof minted for a different stream must not be reusable here.
	req.Header.Set("X-Stream-Proof", sender.proof("some-other-stream"))

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if code := decodeError(t, resp); code != protocol.CodeBadIdentity {
		t.Errorf("code = %q, want bad_identity", code)
	}
}

func TestStreamRejectsADeviceThatIsNotAnEndpoint(t *testing.T) {
	sender, receiver, outsider := newIdentity(t), newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender, receiver, outsider)
	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)

	resp, err := http.DefaultClient.Do(request(t, http.MethodGet, server.URL+"/v1/stream/"+s.ID, outsider, s.ID, nil))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", resp.StatusCode)
	}
	if code := decodeError(t, resp); code != protocol.CodeStreamForbidden {
		t.Errorf("code = %q", code)
	}
}

func TestStreamRejectsTheWrongVerbForYourRole(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender, receiver)
	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)

	// The sender trying to read is an attempt to occupy the receiving end.
	resp, err := http.DefaultClient.Do(request(t, http.MethodGet, server.URL+"/v1/stream/"+s.ID, sender, s.ID, nil))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if code := decodeError(t, resp); code != protocol.CodeStreamForbidden {
		t.Errorf("code = %q, want stream_forbidden", code)
	}
}

func TestUnknownStreamReturnsNotFound(t *testing.T) {
	sender := newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender)

	resp, err := http.DefaultClient.Do(request(t, http.MethodPost, server.URL+"/v1/stream/deadbeef", sender, "deadbeef", nil))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("status = %d, want 404", resp.StatusCode)
	}
	if code := decodeError(t, resp); code != protocol.CodeStreamNotFound {
		t.Errorf("code = %q", code)
	}
}

func TestRendezvousTimeoutReturnsGatewayTimeout(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)

	handler := NewHandler(HandlerOptions{
		Registry: registry,
		Token:    testToken,
		Keys: func(deviceID string) (ed25519.PublicKey, bool) {
			if deviceID == sender.deviceID {
				return sender.public, true
			}
			return nil, false
		},
		RendezvousTimeout: 60 * time.Millisecond,
		IdleTimeout:       time.Second,
	})
	server := httptest.NewServer(handler)
	defer server.Close()

	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)

	resp, err := http.DefaultClient.Do(request(t, http.MethodPost, server.URL+"/v1/stream/"+s.ID, sender, s.ID, bytes.NewReader([]byte("x"))))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusGatewayTimeout {
		t.Fatalf("status = %d, want 504", resp.StatusCode)
	}
	if code := decodeError(t, resp); code != protocol.CodePeerNotAttached {
		t.Errorf("code = %q", code)
	}

	// Sweep cannot collect this one: it only reclaims streams neither end
	// touched, and the sender did attach. Left unreleased, a peer that never
	// shows up would cost the sender a quota slot until it disconnects.
	if registry.Len() != 0 {
		t.Errorf("registry still holds %d streams after a failed rendezvous", registry.Len())
	}
}

func TestMissingStreamIDIsABadRequest(t *testing.T) {
	sender := newIdentity(t)
	registry := NewRegistry(4, time.Minute)
	server := testServer(t, registry, sender)

	resp, err := http.DefaultClient.Do(request(t, http.MethodPost, server.URL+"/v1/stream/", sender, "", nil))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", resp.StatusCode)
	}
}

func TestMaxStreamBytesStopsAnOversizedUpload(t *testing.T) {
	sender, receiver := newIdentity(t), newIdentity(t)
	registry := NewRegistry(4, time.Minute)

	handler := NewHandler(HandlerOptions{
		Registry: registry,
		Token:    testToken,
		Keys: func(deviceID string) (ed25519.PublicKey, bool) {
			switch deviceID {
			case sender.deviceID:
				return sender.public, true
			case receiver.deviceID:
				return receiver.public, true
			}
			return nil, false
		},
		RendezvousTimeout: 2 * time.Second,
		IdleTimeout:       2 * time.Second,
		MaxStreamBytes:    1024,
	})
	server := httptest.NewServer(handler)
	defer server.Close()

	s, _ := registry.Create(sender.deviceID, sender.deviceID, receiver.deviceID)
	url := server.URL + "/v1/stream/" + s.ID

	go func() {
		resp, err := http.DefaultClient.Do(request(t, http.MethodGet, url, receiver, s.ID, nil))
		if err == nil {
			_, _ = io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
		}
	}()

	resp, err := http.DefaultClient.Do(request(t, http.MethodPost, url, sender, s.ID, bytes.NewReader(make([]byte, 64*1024))))
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusRequestEntityTooLarge {
		t.Fatalf("status = %d, want 413", resp.StatusCode)
	}
}
