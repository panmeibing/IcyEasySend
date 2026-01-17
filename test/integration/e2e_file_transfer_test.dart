import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/http_server_manager.dart';
import 'package:icy_easy_send/services/file_transfer_service.dart';
import 'package:icy_easy_send/services/validation_service.dart';

/// End-to-End Integration Tests for File Transfer Flow
/// 
/// These tests verify the complete file transfer workflow including:
/// - Server startup and initialization
/// - File validation and handling
/// - Different file types and sizes
/// - Error handling scenarios
/// 
/// Requirements: All requirements (1.1-10.5)
/// 
/// Note: These tests focus on server-side functionality and file handling
/// rather than actual HTTP transfers, as Flutter test framework blocks
/// real network requests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('E2E File Transfer Flow Tests', () {
    late HTTPServerManager receiverServer;
    late FileTransferService transferService;
    late ValidationService validationService;
    late Directory tempDir;

    setUp(() async {
      receiverServer = HTTPServerManager();
      transferService = FileTransferService();
      validationService = ValidationService();
      tempDir = await Directory.systemTemp.createTemp('e2e_test_');
    });

    tearDown(() async {
      await receiverServer.stopServer();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Complete workflow - Server startup', () async {
      // Step 1: Start receiver server
      final serverResult = await receiverServer.startServer();
      expect(serverResult.success, isTrue, reason: 'Receiver server should start successfully');
      
      final serverAddress = receiverServer.getServerAddress();
      expect(serverAddress, isNotNull, reason: 'Server address should be available');
      expect(serverAddress, contains(':'), reason: 'Server address should contain port');
      
      // Verify server is running
      expect(receiverServer.isRunning(), isTrue, reason: 'Server should be running');
      expect(receiverServer.getCurrentPort(), greaterThanOrEqualTo(8080), 
        reason: 'Server port should be in valid range');
    });

    test('Complete workflow - Small text file creation and validation', () async {
      // Step 1: Create a test file
      final testFile = File('${tempDir.path}/test_small.txt');
      await testFile.writeAsString('Hello, this is a test file!');
      expect(await testFile.exists(), isTrue, reason: 'Test file should be created');
      
      // Step 2: Validate file
      final validationResult = validationService.validateFile(testFile);
      expect(validationResult.isValid, isTrue, reason: 'File should be valid');
      
      // Step 3: Verify file content
      final content = await testFile.readAsString();
      expect(content, equals('Hello, this is a test file!'), 
        reason: 'File content should match');
    });

    test('Complete workflow - Medium binary file handling', () async {
      // Step 1: Create a medium-sized binary file (1MB)
      final testFile = File('${tempDir.path}/test_medium.bin');
      final bytes = List<int>.generate(1024 * 1024, (i) => i % 256);
      await testFile.writeAsBytes(bytes);
      
      expect(await testFile.exists(), isTrue, reason: 'Binary file should be created');
      expect(await testFile.length(), equals(1024 * 1024), 
        reason: 'File size should be 1MB');
      
      // Step 2: Validate file
      final validationResult = validationService.validateFile(testFile);
      expect(validationResult.isValid, isTrue, reason: 'Binary file should be valid');
      
      // Step 3: Verify file content integrity
      final readBytes = await testFile.readAsBytes();
      expect(readBytes.length, equals(bytes.length), 
        reason: 'Read bytes should match written bytes');
      expect(readBytes, equals(bytes), 
        reason: 'File content should be identical');
    });

    test('Complete workflow - Various file types', () async {
      // Test different file types
      final fileTypes = {
        'test.txt': 'Text file content',
        'test.json': '{"key": "value"}',
        'test.xml': '<?xml version="1.0"?><root></root>',
        'test.csv': 'name,age\nJohn,30',
        'test.md': '# Markdown\n\nContent here',
      };

      for (var entry in fileTypes.entries) {
        final testFile = File('${tempDir.path}/${entry.key}');
        await testFile.writeAsString(entry.value);
        
        expect(await testFile.exists(), isTrue, 
          reason: 'File ${entry.key} should be created');
        
        // Validate each file
        final validationResult = validationService.validateFile(testFile);
        expect(validationResult.isValid, isTrue,
          reason: 'File ${entry.key} should be valid');
        
        // Verify content
        final content = await testFile.readAsString();
        expect(content, equals(entry.value),
          reason: 'Content of ${entry.key} should match');
      }
    });

    test('IP address validation workflow', () async {
      // Test valid IP addresses
      final validIPs = [
        '192.168.1.1',
        '10.0.0.1',
        '172.16.0.1',
        '127.0.0.1',
      ];

      for (var ip in validIPs) {
        final result = validationService.validateIPv4(ip);
        expect(result.isValid, isTrue,
          reason: 'IP $ip should be valid');
      }

      // Test invalid IP addresses
      final invalidIPs = [
        '256.1.1.1',
        '192.168.1',
        'abc.def.ghi.jkl',
        '192.168.1.1.1',
        '',
      ];

      for (var ip in invalidIPs) {
        final result = validationService.validateIPv4(ip);
        expect(result.isValid, isFalse,
          reason: 'IP $ip should be invalid');
      }
    });

    test('Server port conflict handling workflow', () async {
      // Start first server
      final firstServer = HTTPServerManager();
      final firstResult = await firstServer.startServer(port: 8080);
      expect(firstResult.success, isTrue, reason: 'First server should start');
      expect(firstServer.getCurrentPort(), equals(8080), 
        reason: 'First server should use port 8080');

      // Start second server (should use next available port)
      final secondServer = HTTPServerManager();
      final secondResult = await secondServer.startServer(port: 8080);
      expect(secondResult.success, isTrue, reason: 'Second server should start');
      expect(secondServer.getCurrentPort(), equals(8081), 
        reason: 'Second server should use port 8081');

      // Verify both servers are running
      expect(firstServer.isRunning(), isTrue);
      expect(secondServer.isRunning(), isTrue);

      // Cleanup
      await firstServer.stopServer();
      await secondServer.stopServer();
      
      expect(firstServer.isRunning(), isFalse);
      expect(secondServer.isRunning(), isFalse);
    });

    test('Error handling - unreachable device', () async {
      // Create a test file
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('test');

      // Try to send to unreachable device
      final result = await transferService.sendFile(
        targetIP: '192.0.2.1:8080', // Non-routable IP
        file: testFile,
      );

      expect(result.success, isFalse, reason: 'Transfer should fail');
      expect(result.errorMessage, isNotNull, reason: 'Error message should be provided');
      expect(result.errorMessage, contains('目标设备不可用'), 
        reason: 'Error should indicate device unavailable');
    });

    test('Error handling - non-existent file', () async {
      final nonExistentFile = File('${tempDir.path}/nonexistent.txt');
      
      final result = await transferService.sendFile(
        targetIP: '127.0.0.1:8080',
        file: nonExistentFile,
      );

      expect(result.success, isFalse, reason: 'Transfer should fail');
      expect(result.errorMessage, contains('文件不存在'), 
        reason: 'Error should indicate file does not exist');
    });

    test('Error handling - invalid file validation', () async {
      final nonExistentFile = File('${tempDir.path}/invalid.txt');
      
      final validationResult = validationService.validateFile(nonExistentFile);
      expect(validationResult.isValid, isFalse, 
        reason: 'Non-existent file should be invalid');
      expect(validationResult.errorMessage, isNotNull,
        reason: 'Error message should be provided');
    });

    test('Large file handling - 10MB', () async {
      // Create a 10MB file
      final largeFile = File('${tempDir.path}/large_file.bin');
      final bytes = List<int>.generate(10 * 1024 * 1024, (i) => i % 256);
      await largeFile.writeAsBytes(bytes);
      
      expect(await largeFile.exists(), isTrue, reason: 'Large file should be created');
      expect(await largeFile.length(), equals(10 * 1024 * 1024), 
        reason: 'File size should be 10MB');

      // Validate large file
      final validationResult = validationService.validateFile(largeFile);
      expect(validationResult.isValid, isTrue, 
        reason: 'Large file should be valid');

      // Verify server can still start with large file present
      final serverResult = await receiverServer.startServer();
      expect(serverResult.success, isTrue, 
        reason: 'Server should start even with large file present');
    });

    test('Special characters in filename', () async {
      // Test files with special characters
      final specialNames = [
        'test file with spaces.txt',
        'test_file_with_underscores.txt',
        'test-file-with-dashes.txt',
        'test.multiple.dots.txt',
        'test(with)parentheses.txt',
      ];

      for (var name in specialNames) {
        final testFile = File('${tempDir.path}/$name');
        await testFile.writeAsString('content');
        
        expect(await testFile.exists(), isTrue,
          reason: 'File with name "$name" should be created');
        
        // Validate file
        final validationResult = validationService.validateFile(testFile);
        expect(validationResult.isValid, isTrue,
          reason: 'File "$name" should be valid');
      }
    });

    test('Empty file handling', () async {
      final emptyFile = File('${tempDir.path}/empty.txt');
      await emptyFile.writeAsString('');
      
      expect(await emptyFile.exists(), isTrue, reason: 'Empty file should be created');
      expect(await emptyFile.length(), equals(0), reason: 'File should be empty');

      // Validate empty file
      final validationResult = validationService.validateFile(emptyFile);
      expect(validationResult.isValid, isTrue, 
        reason: 'Empty file should be valid');
    });

    test('Server restart capability', () async {
      // Start server
      final startResult = await receiverServer.startServer();
      expect(startResult.success, isTrue, reason: 'Server should start');
      expect(receiverServer.isRunning(), isTrue, reason: 'Server should be running');
      
      final firstAddress = receiverServer.getServerAddress();
      expect(firstAddress, isNotNull);

      // Stop server
      await receiverServer.stopServer();
      expect(receiverServer.isRunning(), isFalse, reason: 'Server should be stopped');
      expect(receiverServer.getServerAddress(), isNull, 
        reason: 'Server address should be null when stopped');

      // Restart server
      final restartResult = await receiverServer.startServer();
      expect(restartResult.success, isTrue, reason: 'Server should restart');
      expect(receiverServer.isRunning(), isTrue, reason: 'Server should be running again');
      
      final secondAddress = receiverServer.getServerAddress();
      expect(secondAddress, isNotNull);
    });

    test('File validation - readable files', () async {
      // Create a readable file
      final readableFile = File('${tempDir.path}/readable.txt');
      await readableFile.writeAsString('readable content');
      
      final validationResult = validationService.validateFile(readableFile);
      expect(validationResult.isValid, isTrue, 
        reason: 'Readable file should be valid');
      
      // Verify we can actually read it
      final content = await readableFile.readAsString();
      expect(content, equals('readable content'));
    });

    test('Multiple file operations in sequence', () async {
      // Create multiple files
      final files = <File>[];
      for (int i = 0; i < 5; i++) {
        final file = File('${tempDir.path}/file_$i.txt');
        await file.writeAsString('Content $i');
        files.add(file);
      }

      // Validate all files
      for (var file in files) {
        expect(await file.exists(), isTrue);
        final validationResult = validationService.validateFile(file);
        expect(validationResult.isValid, isTrue);
      }

      // Read all files
      for (int i = 0; i < files.length; i++) {
        final content = await files[i].readAsString();
        expect(content, equals('Content $i'));
      }
    });

    test('Server state consistency', () async {
      // Initially not running
      expect(receiverServer.isRunning(), isFalse);
      expect(receiverServer.getServerAddress(), isNull);
      
      // Start server
      await receiverServer.startServer();
      expect(receiverServer.isRunning(), isTrue);
      expect(receiverServer.getServerAddress(), isNotNull);
      expect(receiverServer.getCurrentPort(), greaterThanOrEqualTo(8080));
      
      // Stop server
      await receiverServer.stopServer();
      expect(receiverServer.isRunning(), isFalse);
      expect(receiverServer.getServerAddress(), isNull);
    });

    test('File size verification', () async {
      final sizes = [
        0,           // Empty
        1024,        // 1KB
        1024 * 1024, // 1MB
        5 * 1024 * 1024, // 5MB
      ];

      for (var size in sizes) {
        final file = File('${tempDir.path}/file_${size}_bytes.bin');
        final bytes = List<int>.generate(size, (i) => i % 256);
        await file.writeAsBytes(bytes);
        
        expect(await file.exists(), isTrue);
        expect(await file.length(), equals(size),
          reason: 'File should be exactly $size bytes');
        
        final validationResult = validationService.validateFile(file);
        expect(validationResult.isValid, isTrue);
      }
    });
  });
}
