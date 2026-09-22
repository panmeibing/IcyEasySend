import 'package:flutter/widgets.dart';

/// Whether inbound confirm dialogs (file / clipboard / pairing) can be shown.
///
/// HarmonyOS (and sometimes Android) may report "background" while a mounted
/// [BuildContext] is still available. Prefer showing UI whenever the context
/// is mounted so requests are not silently dropped.
bool canShowInboundUi({
  required BuildContext? Function()? contextGetter,
  bool Function()? isInBackgroundGetter,
  /// Test / inject hook that bypasses lifecycle checks (e.g. confirmShare).
  bool forceAvailable = false,
}) {
  if (forceAvailable) return true;
  final context = contextGetter?.call();
  if (context != null && context.mounted) return true;
  if (isInBackgroundGetter?.call() ?? false) return false;
  return false;
}
