import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';

/// Port input section widget
class PortInputSection extends StatelessWidget {
  final TextEditingController controller;
  final String? errorMessage;
  final bool isEnabled;
  final VoidCallback onReset;

  const PortInputSection({
    super.key,
    required this.controller,
    this.errorMessage,
    required this.isEnabled,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '目标设备端口',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '默认: ${AppConstants.defaultPort}',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                  prefixIcon: const Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                enabled: isEnabled,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isEnabled ? onReset : null,
              icon: const Icon(Icons.refresh),
              tooltip: '重置为默认端口 (${AppConstants.defaultPort})',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade50,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
