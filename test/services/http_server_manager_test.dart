import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/http_server_manager.dart';
import 'package:http/http.dart' as http;

void main() {
  group('HTTPServerManager', () {
    late HTTPServerManager serverManager;

    setUp(() {
      serverManager = HTTPServerManager();
    });

    tearDown(() async {
      // Always stop the server after each test
      await serverManager.stopServer();
    });

    test('should start server on default port 8080', () async {
      final result = await serverManager.startServer();

      expect(result.success, isTrue);
      expect(result.serverAddress, isNotNull);
      expect(result.errorMessage, isNull);
      expect(serverManager.isRunning(), isTrue);
      expect(serverManager.getCurrentPort(), equals(8080));
    });

    test('should return server address when running', () async {
      await serverManager.startServer();

      final address = serverManager.getServerAddress();
      expect(address, isNotNull);
      expect(address, contains(':8080'));
    });

    test('should stop server successfully', () async {
      await serverManager.startServer();
      expect(serverManager.isRunning(), isTrue);

      await serverManager.stopServer();
      expect(serverManager.isRunning(), isFalse);
      expect(serverManager.getServerAddress(), isNull);
    });

    test('should handle port conflict by trying next port', () async {
      // Start first server on port 8080
      final firstServer = HTTPServerManager();
      await firstServer.startServer(port: 8080);

      // Try to start second server, should use port 8081
      final result = await serverManager.startServer(port: 8080);

      expect(result.success, isTrue);
      expect(serverManager.getCurrentPort(), equals(8081));

      // Cleanup
      await firstServer.stopServer();
    });

    test('should return error when all ports are occupied', () async {
      // Create multiple servers to occupy all ports in range
      final servers = <HTTPServerManager>[];
      
      // Occupy ports 8080-8090 (11 ports)
      for (int i = 0; i <= 10; i++) {
        final server = HTTPServerManager();
        await server.startServer(port: 8080 + i);
        servers.add(server);
      }

      // Try to start another server, should fail
      final result = await serverManager.startServer(port: 8080);

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('端口'));

      // Cleanup all servers
      for (var server in servers) {
        await server.stopServer();
      }
    });

    test('should respond to health check endpoint', () async {
      final result = await serverManager.startServer();
      expect(result.success, isTrue);

      // Make HTTP request to health endpoint
      final address = serverManager.getServerAddress();
      final response = await http.get(Uri.parse('http://$address/health'));

      expect(response.statusCode, equals(200));
      expect(response.body, contains('status'));
      expect(response.body, contains('ok'));
    });

    test('should return success if server already running', () async {
      final firstResult = await serverManager.startServer();
      expect(firstResult.success, isTrue);

      final secondResult = await serverManager.startServer();
      expect(secondResult.success, isTrue);
      expect(secondResult.serverAddress, equals(firstResult.serverAddress));
    });
  });
}
