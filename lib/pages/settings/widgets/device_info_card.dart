import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Device information card widget
class DeviceInfoCard extends StatelessWidget {
  final String deviceName;
  final String deviceModel;
  final bool isEditingName;
  final TextEditingController deviceNameController;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onResetPressed;

  const DeviceInfoCard({
    super.key,
    required this.deviceName,
    required this.deviceModel,
    required this.isEditingName,
    required this.deviceNameController,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCancelPressed,
    required this.onResetPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.deviceNameSetting,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Device Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deviceName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isEditingName)
                        TextField(
                          controller: deviceNameController,
                          decoration: InputDecoration(
                            hintText: l10n.deviceNameHint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          autofocus: true,
                        )
                      else
                        Text(
                          deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isEditingName) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                    onPressed: onSavePressed,
                    tooltip: l10n.confirm,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                    onPressed: onCancelPressed,
                    tooltip: l10n.cancel,
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                    onPressed: onEditPressed,
                    tooltip: l10n.editDeviceName,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    onPressed: onResetPressed,
                    tooltip: l10n.resetDeviceName,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Device Model
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deviceName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  deviceModel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
