import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_page.dart';
import '../services/http_server_manager.dart';

/// MainContainer provides bottom navigation to switch between pages
class MainContainer extends StatefulWidget {
  final HTTPServerManager serverManager;

  const MainContainer({
    super.key,
    required this.serverManager,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final GlobalKey<HistoryPageState> _historyPageKey = GlobalKey<HistoryPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(serverManager: widget.serverManager),
          HistoryPage(key: _historyPageKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh history page when switching to it
          if (index == 1) {
            _historyPageKey.currentState?.refreshHistory();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '历史记录',
          ),
        ],
      ),
    );
  }
}
