import 'dart:io';

import 'ohos_platform.dart';

/// Platform-specific UDP multicast socket options (LocalSend-style).
class MulticastSocketOptions {
  /// TTL for multicast packets. LocalSend uses 2.
  static const int defaultMulticastTtl = 2;

  static void setMulticastTtl(RawDatagramSocket socket, int ttl) {
    try {
      if (Platform.isWindows || Platform.isMacOS) {
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
}
