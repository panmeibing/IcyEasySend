import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/transfer_history.dart';
import '../../services/transfer_history_service.dart';
import '../../utils/format_util.dart';
import '../history/widgets/history_filter_chips.dart';
import '../home/home_ui.dart';
import 'tv_widgets.dart';

const _filesChannel = MethodChannel('com.icyhope.icy_easy_send/files');

bool _isImagePath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return false;
  switch (path.substring(dot + 1).toLowerCase()) {
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'bmp':
      return true;
    default:
      return false;
  }
}

class TvHistoryPage extends StatefulWidget {
  const TvHistoryPage({super.key});

  @override
  State<TvHistoryPage> createState() => TvHistoryPageState();
}

class TvHistoryPageState extends State<TvHistoryPage> {
  final TransferHistoryService _historyService = TransferHistoryService();
  List<TransferHistory> _history = [];
  HistoryFilter _filter = HistoryFilter.all;
  int _selected = 0;
  bool _loading = true;
  String? _openError;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final history = await _historyService.loadHistory();
    if (!mounted) return;
    final current = _filtered;
    final previous = current.isEmpty
        ? null
        : current[_selected.clamp(0, current.length - 1)];
    setState(() {
      _history = history;
      _loading = false;
      final next = _filtered;
      if (previous == null || next.isEmpty) {
        _selected = 0;
        _openError = null;
        return;
      }
      final index = next.indexOf(previous);
      if (index < 0) {
        _selected = 0;
        _openError = null;
        return;
      }
      _selected = index;
    });
  }

  List<TransferHistory> get _filtered {
    switch (_filter) {
      case HistoryFilter.all:
        return _history;
      case HistoryFilter.sent:
        return _history.where((item) => !item.isReceived).toList();
      case HistoryFilter.received:
        return _history.where((item) => item.isReceived).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _filtered;
    final selectedIndex = items.isEmpty
        ? 0
        : _selected.clamp(0, items.length - 1);
    final selected = items.isEmpty ? null : items[selectedIndex];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TvButton(
                    label: l10n.filterAll,
                    primary: _filter == HistoryFilter.all,
                    minWidth: 72,
                    onPressed: () => setState(() {
                      _filter = HistoryFilter.all;
                      _selected = 0;
                    }),
                  ),
                  const SizedBox(width: 8),
                  TvButton(
                    label: l10n.filterSent,
                    primary: _filter == HistoryFilter.sent,
                    minWidth: 72,
                    onPressed: () => setState(() {
                      _filter = HistoryFilter.sent;
                      _selected = 0;
                    }),
                  ),
                  const SizedBox(width: 8),
                  TvButton(
                    label: l10n.filterReceived,
                    primary: _filter == HistoryFilter.received,
                    minWidth: 72,
                    onPressed: () => setState(() {
                      _filter = HistoryFilter.received;
                      _selected = 0;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          l10n.noHistory,
                          style: const TextStyle(
                            fontSize: 18,
                            color: HomeUi.inkMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final kind = item.isReceived
                              ? l10n.received
                              : l10n.sent;
                          return TvRow(
                            title: item.fileName,
                            selected: index == selectedIndex,
                            subtitle:
                                '$kind · ${FormatUtil.formatBytes(item.fileSize)}',
                            onPressed: () => setState(() {
                              _selected = index;
                              _openError = null;
                            }),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: selected == null
              ? const SizedBox.shrink()
              : _Detail(
                  item: selected,
                  openError: _openError,
                  onOpen: () => _open(selected),
                  onDelete: () => _delete(selected),
                  onDeleteAll: _deleteAll,
                ),
        ),
      ],
    );
  }

  Future<void> _open(TransferHistory item) async {
    final l10n = AppLocalizations.of(context);
    final path = item.savedPath;
    if (path == null) {
      setState(() => _openError = l10n.fileNotExist);
      return;
    }
    try {
      if (!File(path).existsSync()) {
        setState(() => _openError = l10n.fileNotExist);
        return;
      }
      if (_isImagePath(path)) {
        if (!mounted) return;
        setState(() => _openError = null);
        await _showImage(path);
        return;
      }
      if (Platform.isAndroid || Platform.isMacOS) {
        // Android launches a viewer in its own task. macOS asks Launch
        // Services to open the file in the default app (Preview for a PDF).
        final error = await _filesChannel.invokeMethod<String>('openFile', {
          'path': path,
        });
        if (!mounted) return;
        setState(() => _openError = _openFailure(l10n, error));
        return;
      }
      final uri = Uri.file(path);
      if (await launchUrl(uri)) {
        if (!mounted) return;
        setState(() => _openError = null);
        return;
      }
      if (!mounted) return;
      setState(() => _openError = l10n.cannotOpenFile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _openError = l10n.cannotOpenFileWithMessage('$e'));
    }
  }

  String? _openFailure(AppLocalizations l10n, String? error) {
    if (error == null) return null;
    if (error == 'no-app' || error == 'missing') return l10n.cannotOpenFile;
    return l10n.cannotOpenFileWithMessage(error);
  }

  Future<void> _showImage(String path) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SizedBox.expand(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  l10n.cannotOpenFile,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(TransferHistory item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return TvChoiceDialog(
          title: l10n.deleteRecord,
          message: item.fileName,
          primaryLabel: l10n.cancel,
          secondaryLabel: l10n.confirm,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (confirmed != true) return;
    await _historyService.deleteTransfer(item);
    await refresh();
  }

  Future<void> _deleteAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return TvChoiceDialog(
          title: l10n.deleteAllRecords,
          message: l10n.clearHistoryMessage,
          primaryLabel: l10n.cancel,
          secondaryLabel: l10n.confirm,
          onPrimary: () => Navigator.of(dialogContext).pop(false),
          onSecondary: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    if (confirmed != true) return;
    await _historyService.clearHistory();
    await refresh();
  }
}

class _Detail extends StatelessWidget {
  final TransferHistory item;
  final String? openError;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onDeleteAll;

  const _Detail({
    required this.item,
    required this.openError,
    required this.onOpen,
    required this.onDelete,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final path = item.savedPath ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.fileName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: HomeUi.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${item.peerDeviceName ?? item.peerIP} · ${FormatUtil.formatBytes(item.fileSize)}',
          style: const TextStyle(fontSize: 16, color: HomeUi.inkMuted),
        ),
        const SizedBox(height: 12),
        Text(l10n.savePath, style: HomeUi.sectionTitleStyle),
        const SizedBox(height: 4),
        Text(path, style: const TextStyle(fontSize: 16, color: HomeUi.ink)),
        if (openError != null) ...[
          const SizedBox(height: 8),
          Text(
            openError!,
            style: const TextStyle(fontSize: 16, color: HomeUi.stoppedAccent),
          ),
        ],
        const SizedBox(height: 20),
        TvButton(label: l10n.openFile, onPressed: onOpen),
        const SizedBox(height: 10),
        TvButton(label: l10n.deleteRecord, onPressed: onDelete),
        const SizedBox(height: 10),
        TvButton(label: l10n.deleteAllRecords, onPressed: onDeleteAll),
      ],
    );
  }
}
