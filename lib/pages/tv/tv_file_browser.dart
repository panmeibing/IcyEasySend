import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../l10n/app_localizations.dart';
import '../../utils/format_util.dart';
import '../../utils/platform_util.dart';
import '../../utils/toast_helper.dart';
import '../home/home_ui.dart';
import 'tv_widgets.dart';

/// In-app browser for Android TV, which has no document picker.
///
/// Returns the selected file paths, or the current directory when
/// [selectDirectory] is set. Returns null when cancelled.
Future<List<String>?> showTvFileBrowser(
  BuildContext context, {
  bool selectDirectory = false,
}) {
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TvFileBrowser(selectDirectory: selectDirectory),
  );
}

class _Entry {
  final String name;
  final String fullPath;
  final bool isDirectory;
  final int? size;

  const _Entry({
    required this.name,
    required this.fullPath,
    required this.isDirectory,
    this.size,
  });
}

class _TvFileBrowser extends StatefulWidget {
  final bool selectDirectory;

  const _TvFileBrowser({required this.selectDirectory});

  @override
  State<_TvFileBrowser> createState() => _TvFileBrowserState();
}

class _TvFileBrowserState extends State<_TvFileBrowser> {
  Directory? _current;
  String? _root;
  List<_Entry> _entries = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _failed = false;
  int _listGeneration = 0;

  @override
  void initState() {
    super.initState();
    _openInitial();
  }

  Future<void> _openInitial() async {
    final save = await PlatformUtil.getReceiveSaveDirectory();
    final start = save ?? Directory('/storage/emulated/0/Download');
    final root = _storageRoot(start.path);
    if (!mounted) return;
    setState(() => _root = root);
    await _open(start);
  }

  String _storageRoot(String start) {
    const shared = '/storage/emulated/0';
    if (start == shared || start.startsWith('$shared/')) return shared;
    return start;
  }

  bool _isUnderRoot(String candidate) {
    final root = _root;
    if (root == null) return false;
    final normalized = path.normalize(candidate);
    final rootPath = path.normalize(root);
    return normalized == rootPath ||
        normalized.startsWith('$rootPath${path.separator}');
  }

  Future<void> _open(Directory directory) async {
    if (_root != null && !_isUnderRoot(directory.path)) return;
    final generation = ++_listGeneration;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final listed = await directory.list(followLinks: false).toList();
      final entries = <_Entry>[];
      for (final entity in listed) {
        final name = path.basename(entity.path);
        if (name.startsWith('.')) continue;
        if (entity is Directory) {
          entries.add(
            _Entry(name: name, fullPath: entity.path, isDirectory: true),
          );
        } else if (entity is File) {
          int? size;
          try {
            size = await entity.length();
          } catch (_) {}
          entries.add(
            _Entry(
              name: name,
              fullPath: entity.path,
              isDirectory: false,
              size: size,
            ),
          );
        }
      }
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      if (!mounted || generation != _listGeneration) return;
      setState(() {
        _current = directory;
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _listGeneration) return;
      final hadDirectory = _current != null;
      setState(() {
        _loading = false;
        _failed = !hadDirectory;
      });
      if (hadDirectory) {
        ToastHelper.showError(
          context,
          AppLocalizations.of(context).permissionDenied,
        );
      }
    }
  }

  void _confirm() {
    if (widget.selectDirectory) {
      final current = _current;
      if (current == null) return;
      Navigator.of(context).pop([current.path]);
      return;
    }
    if (_selected.isEmpty) return;
    Navigator.of(context).pop(_selected.toList());
  }

  void _activate(_Entry entry) {
    if (entry.isDirectory) {
      _open(Directory(entry.fullPath));
      return;
    }
    if (widget.selectDirectory) return;
    setState(() {
      if (!_selected.add(entry.fullPath)) {
        _selected.remove(entry.fullPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final current = _current;
    final parent = current?.parent;
    final canGoUp =
        current != null &&
        parent != null &&
        _root != null &&
        path.normalize(current.path) != path.normalize(_root!) &&
        _isUnderRoot(parent.path);

    final rows = <_Entry>[
      if (canGoUp)
        _Entry(name: '..', fullPath: parent.path, isDirectory: true),
      ..._entries,
    ];

    // Nearly the full screen, so a long file name stays readable beside the actions.
    const sideInset = 48.0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: sideInset, vertical: 24),
      child: SizedBox(
        width: size.width - sideInset * 2,
        height: size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.tvChooseFiles,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: HomeUi.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current?.path ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: HomeUi.inkMuted,
                      ),
                    ),
                    if (!widget.selectDirectory) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selected.isEmpty
                            ? l10n.noFilesSelected
                            : l10n.filesSelected(_selected.length),
                        style: const TextStyle(
                          fontSize: 16,
                          color: HomeUi.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Expanded(child: _body(l10n, rows)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Beside the list, so one right press leaves a long folder.
              SizedBox(
                width: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TvButton(
                      label: l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 12),
                    TvButton(
                      label: l10n.confirm,
                      primary: true,
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, List<_Entry> rows) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          l10n.permissionDenied,
          style: const TextStyle(fontSize: 18, color: HomeUi.inkMuted),
        ),
      );
    }
    if (rows.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          l10n.folderContainsNoFiles,
          style: const TextStyle(fontSize: 18, color: HomeUi.inkMuted),
        ),
      );
    }
    return ListView.separated(
      key: ValueKey(_current?.path),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = rows[index];
        final checked = _selected.contains(entry.fullPath);
        return TvRow(
          title: entry.isDirectory ? '${entry.name}/' : entry.name,
          subtitle: entry.isDirectory
              ? null
              : (entry.size == null ? null : FormatUtil.formatBytes(entry.size!)),
          selected: checked,
          autofocus: index == 0,
          onPressed: () => _activate(entry),
        );
      },
    );
  }
}
