import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:icy_easy_send/utils/constants.dart';

import 'l10n/app_localizations.dart';
import 'pages/main_container.dart';
import 'pages/pairing/pairing_confirm_dialog.dart';
import 'services/android_foreground_service.dart';
import 'services/cache_cleanup_service.dart';
import 'services/clipboard_overlay_service.dart';
import 'services/http_server_manager.dart';
import 'services/identity_service.dart';
import 'services/language_service.dart';
import 'services/pairing_prompter.dart';
import 'services/sharing_intent_service.dart';
import 'utils/dialog_helper.dart';
import 'utils/log_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android: port for foreground-task <-> UI communication
  AndroidForegroundService.initCommunicationPort();

  // Hand the service layer a way to ask the user about inbound pairing without
  // it having to reach into lib/pages itself. Installed before the HTTP server
  // starts, so the first request cannot arrive to a prompter that refuses.
  PairingPrompter.instance = const DialogPairingPrompter();

  // Console logging already works; attach the file sink in the background so
  // cold start is not waiting on path_provider + creating a log file.
  unawaited(LogUtil.init());

  // First frame as soon as possible. Identity, cache cleanup, permissions and
  // the LAN server continue inside [MyApp] after the UI is up.
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final HTTPServerManager _serverManager;
  late final SharingIntentService _sharingIntentService;
  final LanguageService _languageService = LanguageService();

  late final ThemeData _theme = _buildModernTheme();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _serverManager = HTTPServerManager();
    _sharingIntentService = SharingIntentService();
    _sharingIntentService.initialize();

    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // dispose() also clears the in-memory clipboard cache.
    ClipboardOverlayService.instance.dispose();
    _serverManager.dispose();
    _sharingIntentService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Treat only paused/hidden as true background for inbound request policy.
    // `inactive` can occur during system dialogs while still visible.
    final treatAsBackground =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    _serverManager.setInBackground(treatAsBackground);

    LogUtil.dTag(
      LogTags.ui,
      'AppLifecycleState=$state, background=$treatAsBackground',
    );

    if (state == AppLifecycleState.resumed) {
      unawaited(_ensureServerRunningOnResume());
      unawaited(_onAppResumed());
    } else if (treatAsBackground) {
      unawaited(_onAppGoingBackground());
    }
  }

  /// Paint the shell on the first frame; warm prefs/services in the background.
  Future<void> _bootstrap() async {
    LogUtil.iTag(
      LogTags.ui,
      '应用启动: ${AppConstants.projectName} ${AppConstants.version}',
    );

    // Start share capture immediately (shared Future). Do not await before the
    // first paint — Home awaits the same Future when it needs the payload.
    final shareFuture = SharingIntentService.captureInitialSharingEarly();

    // Language may briefly follow the system locale, then snap if the user
    // saved a non-system preference (ListenableBuilder rebuilds).
    unawaited(_languageService.initialize());
    unawaited(_warmIdentity());
    unawaited(_deferredCacheCleanup(shareFuture));

    // Let the first home frame land before permissions / bind compete for the
    // UI isolate (and before any system permission sheet appears).
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    unawaited(_startServices());
  }

  Future<void> _warmIdentity() async {
    try {
      await IdentityService.instance.ensureInitialized();
    } catch (e) {
      LogUtil.wTag(LogTags.system, '初始化设备身份失败: $e');
    }
  }

  /// Wipe leftover file_picker / share cache after the first frame so a large
  /// cache directory cannot stretch time-to-interactive.
  Future<void> _deferredCacheCleanup(Future<Set<String>> shareFuture) async {
    if (!Platform.isAndroid) return;

    await WidgetsBinding.instance.endOfFrame;
    final pendingSharePaths = await shareFuture;

    LogUtil.iTag(LogTags.system, '应用启动时清理缓存（已延后）');
    try {
      await CacheCleanupService().cleanupFilePickerCache(
        excludePaths: pendingSharePaths,
      );
    } catch (e) {
      LogUtil.wTag(LogTags.system, '启动时清理缓存失败: $e');
    }
  }

  Future<void> _startServices() async {
    // Prefer identity ready before /health and multicast announce the key.
    // Notification permission is requested later by the Android FGS path —
    // asking here would pop a system sheet on top of the first home paint.
    try {
      await IdentityService.instance.ensureInitialized();
    } catch (_) {}

    final result = await _serverManager.startServer();
    if (!result.success && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        await DialogHelper.showErrorDialog(
          context,
          message: result.errorMessage ?? l10n.serverUnknownError,
          title: l10n.error,
          confirmText: l10n.confirm,
        );
      });
    }

    if (Platform.isAndroid) {
      // Clipboard overlay is optional UX; keep it off the first-paint path.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      ClipboardOverlayService.instance.ensureInitialized();
      await ClipboardOverlayService.instance.restoreOverlayIfEnabled();
      await ClipboardOverlayService.instance.startClipboardChangeListening();
      await ClipboardOverlayService.instance.refreshCache();
    }
  }

  Future<void> _onAppResumed() async {
    if (!Platform.isAndroid) return;
    ClipboardOverlayService.instance.ensureInitialized();
    await ClipboardOverlayService.instance.restoreOverlayIfEnabled();
    await ClipboardOverlayService.instance.startClipboardChangeListening();
    await ClipboardOverlayService.instance.refreshCache();
  }

  Future<void> _onAppGoingBackground() async {
    if (!Platform.isAndroid) return;
    // Best-effort refresh while we may still have focus briefly.
    await ClipboardOverlayService.instance.refreshCache();
    await ClipboardOverlayService.instance.stopClipboardChangeListening();
  }

  Future<void> _ensureServerRunningOnResume() async {
    if (_serverManager.isRunning()) return;

    LogUtil.wTag(LogTags.server, '应用回到前台但服务器未运行，尝试重启');
    final result = await _serverManager.startServer();
    if (!result.success) {
      LogUtil.eTag(LogTags.server, '恢复服务器失败: ${result.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _languageService,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.projectName,
          theme: _theme,
          locale: _languageService.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (_languageService.locale != null) {
              return _languageService.locale;
            }

            if (locale != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }

            return const Locale('en', 'US');
          },
          home: MainContainer(
            serverManager: _serverManager,
            sharingIntentService: _sharingIntentService,
            languageService: _languageService,
          ),
        );
      },
    );
  }

  /// Soft icy theme — friendly rounded surfaces aligned with the home shell.
  ThemeData _buildModernTheme() {
    const primaryColor = Color(0xFF4BA3F0);
    const surfaceColor = Color(0xFFF3F8FC);
    const radius = 16.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        primary: primaryColor,
      ),

      // AppBar theme - flat and minimal
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2C3E50),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.15,
        ),
      ),

      // Card theme - soft rounded, light border
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: Color(0xFFE2EBF3), width: 1),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          side: const BorderSide(color: Color(0xFFB7D6F5), width: 1),
          foregroundColor: const Color(0xFF2C3E50),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FBFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFE2EBF3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFE2EBF3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        backgroundColor: Colors.white,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF6B7C8F),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: surfaceColor,

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2EBF3),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
