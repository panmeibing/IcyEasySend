import 'dart:math';

class HexUtil {
  HexUtil._();

  static final Random _secureRandom = Random.secure();

  /// Lowercase hex, two digits per byte.
  static String encode(Iterable<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// [byteCount] bytes from a cryptographically secure source, as hex.
  ///
  /// For anything that doubles as a credential: tickets, share tokens,
  /// session ids.
  static String random(int byteCount) =>
      encode(List<int>.generate(byteCount, (_) => _secureRandom.nextInt(256)));
}
