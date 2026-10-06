import 'package:flutter/widgets.dart';

/// How the service layer tells the user something it does not need an answer
/// to.
///
/// Inbound requests are handled far from any widget, but some outcomes still
/// have to reach the screen. The UI layer installs the real implementation at
/// startup; see `AppUserNotifier` in `lib/pages/app_user_notifier.dart`.
abstract class UserNotifier {
  const UserNotifier();

  static UserNotifier instance = const _NoUiUserNotifier();

  /// A brief note that something went through without asking, such as a
  /// request accepted on a valid secret key.
  void showSuccess(BuildContext context, String message);

  /// Completes once the user has dismissed the alert.
  Future<void> showDiskFull(BuildContext context);
}

/// Stands in until the UI layer installs itself, and in tests that never do.
class _NoUiUserNotifier extends UserNotifier {
  const _NoUiUserNotifier();

  @override
  void showSuccess(BuildContext context, String message) {}

  @override
  Future<void> showDiskFull(BuildContext context) async {}
}
