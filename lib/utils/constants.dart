/// Application-wide constants
class AppConstants {
  // Network constants

  /// Default port for file transfer server
  ///
  /// This is the default port used by the HTTP server to listen for incoming
  /// file transfer requests. The server will try this port first, and if it's
  /// occupied, it will try subsequent ports up to [maxServerPort].
  static const int defaultPort = 8080;

  /// Maximum port number to try when starting the server
  ///
  /// If [defaultPort] is occupied, the server will try ports in the range
  /// [defaultPort] to [maxServerPort] until it finds an available one.
  static const int maxServerPort = 8090;
}
