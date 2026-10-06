import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/http_server_manager.dart';
import '../../services/language_service.dart';
import '../home/home_ui.dart';
import 'tv_history_page.dart';
import 'tv_receive_page.dart';
import 'tv_send_page.dart';
import 'tv_settings_page.dart';
import 'tv_widgets.dart';

/// Landscape shell: a vertical nav and one page. Back moves focus to the nav,
/// and backs out of the app only when the nav already has focus.
class TvShell extends StatefulWidget {
  final HTTPServerManager serverManager;
  final LanguageService languageService;

  const TvShell({
    super.key,
    required this.serverManager,
    required this.languageService,
  });

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  int _index = 0;
  final List<FocusNode> _railNodes = List.generate(4, (_) => FocusNode());
  final FocusScopeNode _pageScope = FocusScopeNode(debugLabel: 'tv-page');
  final GlobalKey<TvHistoryPageState> _historyKey = GlobalKey();
  final GlobalKey<TvReceivePageState> _receiveKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _railNodes.length; i++) {
      final index = i;
      _railNodes[i].onKeyEvent = (node, event) => _onRailKey(index, event);
    }
    widget.serverManager.setHistoryRefreshCallback(() {
      _historyKey.currentState?.refresh();
      _receiveKey.currentState?.refreshRecent();
    });
    widget.serverManager.startNetworkMonitoring();
  }

  @override
  void dispose() {
    widget.serverManager.stopNetworkMonitoring();
    for (final node in _railNodes) {
      node.dispose();
    }
    _pageScope.dispose();
    super.dispose();
  }

  KeyEventResult _onRailKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (index < _railNodes.length - 1) {
        _railNodes[index + 1].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (index > 0) {
        _railNodes[index - 1].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _focusPage();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Left from the leftmost control on a page returns to the nav. Up and down
  /// stay inside the page, because this scope does not see the nav buttons.
  KeyEventResult _onPageKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.arrowLeft) {
      return KeyEventResult.ignored;
    }
    final current = FocusManager.instance.primaryFocus;
    if (current == null || current == _pageScope) {
      _railNodes[_index].requestFocus();
      return KeyEventResult.handled;
    }
    final edge = current.rect.left;
    final hasControlOnTheLeft = _pageScope.traversalDescendants.any((
      candidate,
    ) {
      return candidate != current &&
          candidate.canRequestFocus &&
          !candidate.skipTraversal &&
          candidate.rect.center.dx <= edge;
    });
    if (hasControlOnTheLeft) return KeyEventResult.ignored;
    _railNodes[_index].requestFocus();
    return KeyEventResult.handled;
  }

  void _focusPage() {
    final nodes = _pageScope.traversalDescendants
        .where((node) => node.canRequestFocus && !node.skipTraversal)
        .toList();
    if (nodes.isEmpty) return;
    nodes.sort((a, b) {
      final top = a.rect.top.compareTo(b.rect.top);
      if (top != 0) return top;
      return a.rect.left.compareTo(b.rect.left);
    });
    nodes.first.requestFocus();
  }

  bool get _railFocused => _railNodes.any((node) => node.hasFocus);

  /// Keep the remote on the nav after select. Page autofocus would otherwise
  /// take the highlight, and the next up/down would move inside the page.
  void _selectPage(int index) {
    setState(() => _index = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _index != index) return;
      if (_focusIsInPage(FocusManager.instance.primaryFocus)) {
        _railNodes[index].requestFocus();
      }
    });
  }

  bool _focusIsInPage(FocusNode? node) {
    while (node != null) {
      if (node == _pageScope) return true;
      node = node.parent;
    }
    return false;
  }

  Widget _page() {
    switch (_index) {
      case 0:
        return TvReceivePage(
          key: _receiveKey,
          serverManager: widget.serverManager,
        );
      case 1:
        return TvSendPage(serverManager: widget.serverManager);
      case 2:
        return TvHistoryPage(key: _historyKey);
      default:
        return TvSettingsPage(languageService: widget.languageService);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.serverManager.setContext(context);
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.receiveFiles,
      l10n.sendFiles,
      l10n.navHistory,
      l10n.navSettings,
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_railFocused) {
          SystemNavigator.pop();
        } else {
          _railNodes[_index].requestFocus();
        }
      },
      child: Scaffold(
        backgroundColor: HomeUi.pageBackground,
        body: Padding(
          padding: const EdgeInsets.all(48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Icy Easy Send',
                      style: HomeUi.sectionTitleStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < labels.length; i++) ...[
                      TvButton(
                        label: labels[i],
                        expand: true,
                        primary: _index == i,
                        autofocus: i == 0,
                        focusNode: _railNodes[i],
                        onPressed: () => _selectPage(i),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: FocusScope(
                  node: _pageScope,
                  onKeyEvent: _onPageKey,
                  child: _page(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
