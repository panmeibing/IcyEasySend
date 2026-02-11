import 'package:flutter/material.dart';

import '../services/http_server_manager.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

/// MainContainer provides bottom navigation to switch between pages
class MainContainer extends StatefulWidget {
  final HTTPServerManager serverManager;

  const MainContainer({super.key, required this.serverManager});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final GlobalKey<HistoryPageState> _historyPageKey =
      GlobalKey<HistoryPageState>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(serverManager: widget.serverManager),
          HistoryPage(key: _historyPageKey),
          SettingsPage(serverManager: widget.serverManager),
        ],
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
              _currentIndex = index;
            });
            // Refresh history page when switching to it
            if (index == 1) {
              _refreshHistory();
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '主页'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: '历史记录'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
          ],
        ),
      ),
    );
  }
}
