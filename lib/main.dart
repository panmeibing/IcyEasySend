import 'package:flutter/material.dart';
import 'services/http_server_manager.dart';
import 'services/permission_service.dart';
import 'pages/main_container.dart';
import 'utils/error_messages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final HTTPServerManager _serverManager = HTTPServerManager();
  final PermissionService _permissionService = PermissionService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _serverManager.stopServer();
    super.dispose();
  }

  /// Initialize the app: request permissions and start HTTP server
  ///
  Future<void> _initializeApp() async {
    // Step 1: Request necessary permissions
    await _requestPermissions();

    // Step 2: Initialize the HTTP server
    await _initializeServer();
  }

  /// Request necessary permissions on app startup
  Future<void> _requestPermissions() async {
    // Check if permissions are already granted
    final hasPermissions = await _permissionService.hasAllPermissions();

    if (!hasPermissions) {
      // Request permissions
      final result = await _permissionService.requestAllPermissions();

      if (!result.granted && mounted) {
        // Show warning if permissions are not granted
        // User can still use the app, but will be prompted again when needed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? '某些权限未授予，部分功能可能受限'),
                duration: const Duration(seconds: 5),
                action: result.permanentlyDenied
                    ? SnackBarAction(
                        label: '设置',
                        onPressed: () => _permissionService.openAppSettings(),
                      )
                    : null,
              ),
            );
          }
        });
      }
    }
  }

  /// Initialize the HTTP server on app startup
  Future<void> _initializeServer() async {
    final result = await _serverManager.startServer();
    setState(() {
      _isInitialized = true;
      if (!result.success) {
        // Show error dialog if server fails to start
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('错误'),
                content: Text(
                  result.errorMessage ?? ErrorMessages.serverUnknownError,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Icy Easy Send',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _isInitialized
          ? MainContainer(serverManager: _serverManager)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
