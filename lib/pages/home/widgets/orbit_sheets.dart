import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/transfer_file_item.dart';
import '../../../utils/constants.dart';
import '../home_ui.dart';
import 'quick_ip_chips.dart';

const BorderRadius _sheetRadius = BorderRadius.vertical(top: Radius.circular(24));

/// Bottom sheet: pick files or folder.
Future<void> showOrbitPickSheet({
  required BuildContext context,
  required VoidCallback onSelectFiles,
  required VoidCallback onSelectFolder,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              Text(
                l10n.selectFiles,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dragDropHint,
                style: HomeUi.captionStyle.copyWith(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickTile(
                      icon: Icons.insert_drive_file_rounded,
                      label: l10n.selectFiles,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelectFiles();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickTile(
                      icon: Icons.folder_rounded,
                      label: l10n.selectFolder,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelectFolder();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: HomeUi.inkMuted,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeUi.fieldFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: HomeUi.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26, color: HomeUi.primary),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HomeUi.ink,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for clipboard / diagnostics / manual endpoint.
Future<void> showOrbitMoreSheet({
  required BuildContext context,
  required bool canRequestClipboard,
  required VoidCallback onClipboard,
  required VoidCallback onDiagnostics,
  required TextEditingController ipController,
  required TextEditingController portController,
  required TextEditingController secretKeyController,
  FocusNode? ipFocusNode,
  FocusNode? portFocusNode,
  FocusNode? secretKeyFocusNode,
  required ValueNotifier<int> endpointUiTick,
  required String? Function() ipErrorReader,
  required String? Function() portErrorReader,
  required List<String> ipHistory,
  required String? serverAddress,
  required bool isEnabled,
  required ValueChanged<String> onIPSelected,
  required ValueChanged<String> onIPDeleted,
  required VoidCallback onPortReset,
  required VoidCallback onSecretHelp,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Text(
                  l10n.moreActions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.tonal(
                          onPressed: canRequestClipboard
                              ? () {
                                  Navigator.pop(ctx);
                                  onClipboard();
                                }
                              : null,
                          style: HomeUi.softTonalButton(),
                          child: Text(l10n.syncClipboard),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDiagnostics();
                          },
                          style: HomeUi.softTonalButton(),
                          child: Text(l10n.networkDiagnostics),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.targetDeviceIP,
                  style: HomeUi.sectionTitleStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: endpointUiTick,
                  builder: (context, _, child) {
                    return _OrbitManualEndpointForm(
                      ipController: ipController,
                      portController: portController,
                      secretKeyController: secretKeyController,
                      ipFocusNode: ipFocusNode,
                      portFocusNode: portFocusNode,
                      secretKeyFocusNode: secretKeyFocusNode,
                      ipErrorMessage: ipErrorReader(),
                      portErrorMessage: portErrorReader(),
                      ipHistory: ipHistory,
                      serverAddress: serverAddress,
                      isEnabled: isEnabled,
                      onIPSelected: onIPSelected,
                      onIPDeleted: onIPDeleted,
                      onPortReset: onPortReset,
                      onSecretHelp: onSecretHelp,
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: HomeUi.softFilledButton(),
                    child: Text(l10n.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Manual endpoint fields for the more-actions sheet.
class _OrbitManualEndpointForm extends StatelessWidget {
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController secretKeyController;
  final FocusNode? ipFocusNode;
  final FocusNode? portFocusNode;
  final FocusNode? secretKeyFocusNode;
  final String? ipErrorMessage;
  final String? portErrorMessage;
  final List<String> ipHistory;
  final String? serverAddress;
  final bool isEnabled;
  final ValueChanged<String> onIPSelected;
  final ValueChanged<String> onIPDeleted;
  final VoidCallback onPortReset;
  final VoidCallback onSecretHelp;

  const _OrbitManualEndpointForm({
    required this.ipController,
    required this.portController,
    required this.secretKeyController,
    this.ipFocusNode,
    this.portFocusNode,
    this.secretKeyFocusNode,
    required this.ipErrorMessage,
    required this.portErrorMessage,
    required this.ipHistory,
    required this.serverAddress,
    required this.isEnabled,
    required this.onIPSelected,
    required this.onIPDeleted,
    required this.onPortReset,
    required this.onSecretHelp,
  });

  InputDecoration _decoration({
    required String hintText,
    String? errorText,
    Widget? suffix,
  }) {
    return HomeUi.fieldDecoration(
      hintText: hintText,
      errorText: errorText,
      suffix: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: ipController,
          focusNode: ipFocusNode,
          enabled: isEnabled,
          keyboardType: TextInputType.number,
          decoration: _decoration(
            hintText: l10n.ipHint,
            errorText: ipErrorMessage,
            suffix: ipHistory.isEmpty
                ? null
                : PopupMenuButton<String>(
                    tooltip: l10n.history,
                    onSelected: onIPSelected,
                    itemBuilder: (context) {
                      return ipHistory.map((ip) {
                        return PopupMenuItem<String>(
                          value: ip,
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(ip)),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: HomeUi.stoppedAccent,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onIPDeleted(ip);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.history_rounded, size: 20),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        QuickIpChips(
          serverAddress: serverAddress,
          isEnabled: isEnabled,
          onIPSelected: onIPSelected,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: portController,
          focusNode: portFocusNode,
          enabled: isEnabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: _decoration(
            hintText: l10n.port,
            errorText: portErrorMessage,
            suffix: IconButton(
              onPressed: isEnabled ? onPortReset : null,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: l10n.resetToDefaultPort(AppConstants.defaultPort),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: secretKeyController,
          focusNode: secretKeyFocusNode,
          enabled: isEnabled,
          obscureText: true,
          maxLength: 20,
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              null,
          decoration: _decoration(
            hintText: l10n.targetDeviceSecretKey,
            suffix: IconButton(
              onPressed: onSecretHelp,
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              color: HomeUi.inkMuted,
              tooltip: l10n.secretKeyDescription,
            ),
          ),
        ),
      ],
    );
  }
}

/// File list detail sheet (orbit core tap when files exist).
Future<void> showOrbitFilesSheet({
  required BuildContext context,
  required List<TransferFileItem> items,
  required bool isSending,
  required VoidCallback onAdd,
  required VoidCallback onClear,
  required ValueChanged<int> onRemove,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
    builder: (ctx) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  Text(
                    l10n.filesSelected(items.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                          decoration: BoxDecoration(
                            color: HomeUi.fieldFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.transferName.contains('/')
                                    ? Icons.folder_outlined
                                    : Icons.insert_drive_file_outlined,
                                color: HomeUi.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.transferName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: isSending
                                    ? null
                                    : () {
                                        onRemove(index);
                                        setModalState(() {});
                                        if (items.isEmpty) {
                                          Navigator.pop(ctx);
                                        }
                                      },
                                icon: const Icon(Icons.close_rounded),
                                color: HomeUi.inkMuted,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.tonal(
                            onPressed: isSending
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    onAdd();
                                  },
                            style: HomeUi.softTonalButton(),
                            child: Text(l10n.selectFiles),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () {
                                    Navigator.pop(ctx);
                                    onClear();
                                  },
                            style: HomeUi.softOutlinedButton(),
                            child: Text(l10n.clearSelection),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: HomeUi.softFilledButton(),
                      child: Text(l10n.close),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: HomeUi.borderSoft,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
