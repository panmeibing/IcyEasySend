import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../services/user_notifier.dart';
import '../utils/dialog_helper.dart';
import '../utils/toast_helper.dart';

/// [UserNotifier] backed by the app's toasts and dialogs.
class AppUserNotifier extends UserNotifier {
  const AppUserNotifier();

  @override
  void showSuccess(BuildContext context, String message) {
    ToastHelper.showSuccess(context, message);
  }

  @override
  Future<void> showDiskFull(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DialogHelper.showErrorDialog(
      context,
      title: l10n.diskFullTitle,
      message: l10n.storageInsufficient,
      confirmText: l10n.gotIt,
    );
  }
}
