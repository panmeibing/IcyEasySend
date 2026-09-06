import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/http_server_manager.dart';
import '../services/language_service.dart';
import '../services/sharing_intent_service.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

/// MainContainer provides bottom navigation to switch between pages
class MainContainer extends StatefulWidget {
  final HTTPServerManager serverManager;
  final SharingIntentService sharingIntentService;
  final LanguageService languageService;

  const MainContainer({
    super.key,
    required this.serverManager,
    required this.sharingIntentService,
    required this.languageService,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  /// Only build History/Settings after the user opens them once so cold start
  /// does not pay for three full tab trees behind an [IndexedStack].
  final Set<int> _visitedTabs = {0};
  final GlobalKey<HistoryPageState> _historyPageKey =
      GlobalKey<HistoryPageState>();
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    // Register the refresh callback with the server manager
    widget.serverManager.setHistoryRefreshCallback(_refreshHistory);

    // Start network monitoring
    widget.serverManager.startNetworkMonitoring();
  }

  @override
  void dispose() {
    widget.serverManager.stopNetworkMonitoring();
    super.dispose();
  }

  /// Public method to refresh history from external calls
  void _refreshHistory() {
    _historyPageKey.currentState?.refreshHistory();
  }

  Widget _tabAt(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return HomePage(
          key: _homePageKey,
          serverManager: widget.serverManager,
          sharingIntentService: widget.sharingIntentService,
        );
      case 1:
        return HistoryPage(key: _historyPageKey);
      case 2:
        return SettingsPage(
          serverManager: widget.serverManager,
          languageService: widget.languageService,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [_tabAt(0), _tabAt(1), _tabAt(2)],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _visitedTabs.add(index);
              _currentIndex = index;
            });
            // Refresh history page when switching to it
            if (index == 1) {
              // Defer until after the first build of HistoryPage.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _refreshHistory();
              });
            }
            // Reload IP validation setting when switching to home page
            if (index == 0) {
              _homePageKey.currentState?.reloadIPValidationSetting();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: l10n.navHistory,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
