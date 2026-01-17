import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/health_check_handler.dart';
import 'package:icy_easy_send/services/file_transfer_handler.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('HealthCheckHandler', () {
    late HealthCheckHandler handler;

    setUp(() {
      handler = HealthCheckHandler();
    });

    test('should return 200 OK with correct JSON format', () async {
      // Create a mock request
      final request = Request('GET', Uri.parse('http://localhost:8080/health'));
      
      // Call the handler
      final response = handler.handleHealthCheck(request);
      
      // Verify response
      expect(response.statusCode, equals(200));
      expect(response.headers['Content-Type'], equals('application/json'));
      
      // Parse and verify JSON body
      final body = await response.readAsString();
      final json = jsonDecode(body);
      
      expect(json['status'], equals('ok'));
      expect(json['timestamp'], isA<int>());
      expect(json['deviceName'], isA<String>());
    });
  });

  group('FileTransferHandler', () {
    late FileTransferHandler handler;

    setUp(() {
      handler = FileTransferHandler();
    });

    test('should reject non-multipart requests', () async {
      // Create a request without multipart content-type
      final request = Request(
        'POST',
        Uri.parse('http://localhost:8080/transfer'),
        body: 'test',
      );
      
      // Call the handler
      final response = await handler.handleFileTransfer(request);
      
      // Verify response
      expect(response.statusCode, equals(400));
      
      final body = await response.readAsString();
      final json = jsonDecode(body);
      
      expect(json['success'], equals(false));
      expect(json['message'], contains('multipart/form-data'));
    });
  });
}
