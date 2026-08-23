package signal

import (
	"context"
	"testing"
)

// fakeSession builds a session that is registerable but never writes anywhere.
func fakeSession(deviceID string) *Session {
	return newSession(deviceID, "session-"+deviceID, nil, nil, func() {})
}

func collect(updates []PresenceUpdate) map[string]bool {
	seen := make(map[string]bool, len(updates))
	for _, u := range updates {
		seen[u.To.DeviceID+"->"+u.DeviceID] = u.Online
	}
	return seen
}

func TestSubscribeIsIgnoredForAnUnregisteredDevice(t *testing.T) {
	hub := NewHub()

	if updates := hub.Subscribe("ghost", []string{"someone"}); updates != nil {
		t.Errorf("got %d updates, want none", len(updates))
	}
}

func TestSubscribeIgnoresSelfAndEmptyEntries(t *testing.T) {
	hub := NewHub()
	alice := fakeSession("alice")
	hub.Register(alice)

	// Subscribing to yourself would make you your own mutual watcher and echo
	// your presence back at you.
	if updates := hub.Subscribe("alice", []string{"alice", ""}); len(updates) != 0 {
		t.Errorf("got %v, want no updates", collect(updates))
	}
}

func TestMutualSubscriptionNotifiesBothSides(t *testing.T) {
	hub := NewHub()
	alice, bob := fakeSession("alice"), fakeSession("bob")
	hub.Register(alice)
	hub.Register(bob)

	if updates := hub.Subscribe("alice", []string{"bob"}); len(updates) != 0 {
		t.Fatalf("one-sided subscription leaked %v", collect(updates))
	}

	got := collect(hub.Subscribe("bob", []string{"alice"}))
	if online, ok := got["bob->alice"]; !ok || !online {
		t.Errorf("bob should learn alice is online, got %v", got)
	}
	if online, ok := got["alice->bob"]; !ok || !online {
		t.Errorf("alice should learn bob is online, got %v", got)
	}
}

func TestUnsubscribingMarksTheDeviceOfflineForTheFormerWatcher(t *testing.T) {
	hub := NewHub()
	alice, bob := fakeSession("alice"), fakeSession("bob")
	hub.Register(alice)
	hub.Register(bob)
	hub.Subscribe("alice", []string{"bob"})
	hub.Subscribe("bob", []string{"alice"})

	// Alice stops watching bob. Bob must be told, or his UI would keep showing
	// alice as reachable through the relay forever.
	got := collect(hub.Subscribe("alice", nil))
	if online, ok := got["bob->alice"]; !ok || online {
		t.Errorf("bob should learn alice went away, got %v", got)
	}
}

func TestUnregisterNotifiesMutualWatchersOnly(t *testing.T) {
	hub := NewHub()
	alice, bob, carol := fakeSession("alice"), fakeSession("bob"), fakeSession("carol")
	hub.Register(alice)
	hub.Register(bob)
	hub.Register(carol)

	hub.Subscribe("alice", []string{"bob", "carol"})
	hub.Subscribe("bob", []string{"alice"})
	// Carol watches nobody, so she has no mutual relationship with alice.

	watchers, removed := hub.Unregister(alice)
	if !removed {
		t.Fatal("alice should have been unregistered")
	}
	if len(watchers) != 1 || watchers[0].DeviceID != "bob" {
		t.Fatalf("watchers = %v, want just bob", watchers)
	}
	if _, ok := hub.Lookup("alice"); ok {
		t.Error("alice should be gone")
	}
}

func TestUnregisterIgnoresASupersededSession(t *testing.T) {
	hub := NewHub()
	first := fakeSession("alice")
	second := fakeSession("alice")

	hub.Register(first)
	hub.Register(second)

	// The stale connection closing must not evict the device that replaced it.
	if watchers, removed := hub.Unregister(first); removed || watchers != nil {
		t.Errorf("got removed=%v watchers=%v, want no-op", removed, watchers)
	}
	if session, ok := hub.Lookup("alice"); !ok || session != second {
		t.Error("the newer session should still be registered")
	}
}

func TestRegisterReturnsThePreviousSession(t *testing.T) {
	hub := NewHub()
	first := fakeSession("alice")

	if previous := hub.Register(first); previous != nil {
		t.Error("the first registration has no predecessor")
	}
	if previous := hub.Register(fakeSession("alice")); previous != first {
		t.Error("re-registering should hand back the stale session to close")
	}
	if hub.Count() != 1 {
		t.Errorf("Count = %d, want 1", hub.Count())
	}
}

func TestPublicKeyIsOnlyAvailableForConnectedDevices(t *testing.T) {
	hub := NewHub()
	alice := fakeSession("alice")
	hub.Register(alice)

	if _, ok := hub.PublicKey("alice"); !ok {
		t.Error("a connected device should expose its key to the data plane")
	}
	// A device that never authenticated has no key, so it cannot attach to a
	// stream even if it somehow learned the id.
	if _, ok := hub.PublicKey("stranger"); ok {
		t.Error("an unknown device must not resolve to a key")
	}

	hub.Unregister(alice)
	if _, ok := hub.PublicKey("alice"); ok {
		t.Error("a disconnected device must not resolve to a key")
	}
}

func TestPresenceForAnOfflineMutualPeerIsReportedAsOffline(t *testing.T) {
	hub := NewHub()
	alice, bob := fakeSession("alice"), fakeSession("bob")
	hub.Register(alice)
	hub.Register(bob)

	hub.Subscribe("bob", []string{"alice"})
	hub.Unregister(bob)
	// Bob's subscription is gone with him, so alice learns nothing.
	if updates := hub.Subscribe("alice", []string{"bob"}); len(updates) != 0 {
		t.Errorf("got %v, want no updates", collect(updates))
	}
}

func TestSessionSendFailsAfterClose(t *testing.T) {
	session := newSession("alice", "s1", nil, nil, func() {})
	if !session.Send(map[string]string{"type": "ping"}) {
		t.Fatal("a live session should accept a message")
	}

	session.Close()
	if session.Send(map[string]string{"type": "ping"}) {
		t.Error("a closed session must not accept messages")
	}
}

func TestSessionDisconnectsAClientThatStopsReading(t *testing.T) {
	session := newSession("alice", "s1", nil, nil, func() {})

	// Nothing drains the queue here, standing in for a client that has stopped
	// reading. Once it is full the session is dropped rather than blocking the
	// peers that are trying to reach it.
	for i := 0; i < outboundBuffer; i++ {
		if !session.Send(map[string]int{"n": i}) {
			t.Fatalf("message %d should have been queued", i)
		}
	}
	if session.Send(map[string]string{"type": "overflow"}) {
		t.Fatal("the overflowing message should be refused")
	}

	select {
	case <-session.closed:
	default:
		t.Error("the session should have closed itself")
	}
}

func TestSessionCloseIsIdempotent(t *testing.T) {
	cancelled := 0
	session := newSession("alice", "s1", nil, nil, func() { cancelled++ })

	session.Close()
	session.Close()

	if cancelled != 1 {
		t.Errorf("cancel called %d times, want 1", cancelled)
	}
}

var _ = context.Background
