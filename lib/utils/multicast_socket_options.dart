import 'dart:io';

import 'ohos_platform.dart';

/// Platform-specific UDP multicast socket options (LocalSend-style).
class MulticastSocketOptions {
  /// TTL for multicast packets. LocalSend uses 2.
  static const int defaultMulticastTtl = 2;

  static void setMulticastTtl(RawDatagramSocket socket, int ttl) {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isIOS) {
        // IPPROTO_IP = 0, IP_MULTICAST_TTL = 10 (Winsock / BSD)
        socket.setRawOption(RawSocketOption.fromInt(0, 10, ttl));
      } else if (Platform.isLinux || Platform.isAndroid || isOhosPlatform) {
        // IPPROTO_IP = 0, IP_MULTICAST_TTL = 33 (linux/in.h); OHOS uses Linux-like sockets
        socket.setRawOption(RawSocketOption.fromInt(0, 33, ttl));
      }
    } catch (_) {
      // Best-effort; broadcast fallback may still work.
    }
  }

  /// Pins the next multicast send to [interfaceAddress].
  ///
  /// One socket sends on a single interface. Without this, every announcement
  /// follows the default route and a second LAN adapter (Ethernet next to
  /// Wi-Fi, a hotspot, a VPN) never sees it.
  static void setMulticastInterface(
    RawDatagramSocket socket,
    InternetAddress interfaceAddress,
  ) {
    try {
      if (interfaceAddress.type != InternetAddressType.IPv4) {
        return;
      }
      // IP_MULTICAST_IF: 9 on Winsock/BSD, 32 on Linux/Android.
      // OHOS uses Linux-like sockets, same as IP_MULTICAST_TTL above.
      final option =
          (Platform.isLinux || Platform.isAndroid || isOhosPlatform) ? 32 : 9;
      socket.setRawOption(
        RawSocketOption(
          RawSocketOption.levelIPv4,
          option,
          interfaceAddress.rawAddress,
        ),
      );
    } catch (_) {
      // Best-effort; the socket still sends on the default route.
    }
  }
}
