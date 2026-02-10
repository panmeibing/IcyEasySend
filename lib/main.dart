import 'package:flutter/material.dart';

import 'pages/main_container.dart';
import 'services/http_server_manager.dart';
import 'services/permission_service.dart';
import 'utils/dialog_helper.dart';
import 'utils/error_messages.dart';
import 'utils/toast_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final HTTPServerManager _serverManager;
  late final PermissionService _permissionService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _serverManager = HTTPServerManager();
    _permissionService = PermissionService();

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
            ToastHelper.showWarning(
              context,
              result.errorMessage ?? '某些权限未授予，部分功能可能受限',
              duration: const Duration(seconds: 5),
            );

            // If permanently denied, show a dialog with option to open settings
            if (result.permanentlyDenied) {
              Future.delayed(const Duration(milliseconds: 500), () async {
                if (mounted) {
                  final confirmed = await DialogHelper.showConfirmDialog(
                    context,
                    title: '权限被拒绝',
                    message: '某些权限已被永久拒绝，请在设置中手动开启',
                    confirmText: '打开设置',
                    cancelText: '取消',
                    icon: Icons.settings,
                    iconColor: Colors.orange,
                  );

                  if (confirmed) {
                    _permissionService.openAppSettings();
                  }
                }
              });
            }
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
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            await DialogHelper.showErrorDialog(
              context,
              message: result.errorMessage ?? ErrorMessages.serverUnknownError,
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
      theme: _buildModernTheme(),
      home: _isInitialized
          ? MainContainer(serverManager: _serverManager)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  /// Build modern, clean, and flat theme
  ThemeData _buildModernTheme() {
    const primaryColor = Color(0xFF2196F3); // Modern blue
    const surfaceColor = Color(0xFFFAFAFA); // Light gray background

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),

      // AppBar theme - flat and minimal
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF212121),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
          letterSpacing: 0.15,
        ),
      ),

      // Card theme - minimal elevation and rounded corners
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),

      // Input decoration theme - clean and modern
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Elevated button theme - flat and modern
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: Colors.grey.shade400),
        ),
      ),

      // Bottom navigation bar theme - clean and flat
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF757575),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE0E0E0),
      ),

      // Scaffold background
      scaffoldBackgroundColor: surfaceColor,
    );
  }
}
