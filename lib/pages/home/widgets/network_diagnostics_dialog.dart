import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';
import '../../../utils/dialog_helper.dart';
import '../../../utils/network_diagnostics.dart';
import '../../../utils/network_util.dart';
import '../../../utils/toast_helper.dart';

/// Dialog showing a network diagnostics report.
class NetworkDiagnosticsDialog {
  NetworkDiagnosticsDialog._();

  /// Runs diagnostics behind a loading dialog, then shows the report.
  ///
  /// Returns when the report is dismissed or the run has failed.
  static Future<void> run(
    BuildContext context, {
    String? targetIP,
    int? targetPort,
  }) async {
    final l10n = AppLocalizations.of(context);
    DialogHelper.showLoadingDialog(context, message: l10n.runningDiagnostics);

    DiagnosticsReport report;
    try {
      report = await NetworkDiagnostics.runDiagnostics(
        targetIP: targetIP,
        targetPort: targetPort,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ToastHelper.showError(context, '${l10n.error}: $e');
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    await show(
      context,
      report: report,
      targetIP: targetIP,
      targetPort: targetPort,
    );
  }

  /// Show the diagnostics report dialog.
  ///
  /// Returns when the dialog is dismissed.
  static Future<void> show(
    BuildContext context, {
    required DiagnosticsReport report,
    String? targetIP,
    int? targetPort,
    VoidCallback? onClose,
  }) async {
    final l10n = AppLocalizations.of(context);
    final separator = AppConstants.diagInfoSeparator;
    final reportHeader = StringBuffer();
    reportHeader.writeln(separator * 3);
    reportHeader.writeln(l10n.targetDeviceInfo);
    reportHeader.writeln(separator * 3);
    if (targetIP != null) {
      reportHeader.writeln('${l10n.ipAddress}: $targetIP');
      reportHeader.writeln(
        '${l10n.port}: ${targetPort ?? AppConstants.defaultPort}',
      );
      reportHeader.writeln(
        '${l10n.fullAddress}: ${NetworkUtil.buildHttpUrl(targetIP, "", targetPort: targetPort ?? AppConstants.defaultPort)}',
      );
    } else {
      reportHeader.writeln(l10n.targetNotSet);
    }
    reportHeader.writeln(separator * 3);
    reportHeader.writeln();

    final fullReport = reportHeader.toString() + report.toString();

    await DialogHelper.showCustomDialog(
      context,
      title: Row(
        children: [
          const Icon(Icons.network_check, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.diagnosticsReport)),
        ],
      ),
      content: SingleChildScrollView(
        child: SelectableText(
          fullReport,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: fullReport));
            ToastHelper.showSuccess(context, l10n.reportCopied);
          },
          child: Text(l10n.copy),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
