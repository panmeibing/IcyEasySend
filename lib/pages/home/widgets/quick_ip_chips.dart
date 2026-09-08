import 'package:flutter/material.dart';

import '../home_ui.dart';

/// Capsule chips for common LAN prefixes / hosts.
class QuickIpChips extends StatelessWidget {
  final String? serverAddress;
  final bool isEnabled;
  final ValueChanged<String> onIPSelected;

  const QuickIpChips({
    super.key,
    this.serverAddress,
    required this.isEnabled,
    required this.onIPSelected,
  });

  String? _extractNetworkSegment() {
    if (serverAddress == null || serverAddress!.isEmpty) {
      return null;
    }

    final addressPattern = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})');
    final match = addressPattern.firstMatch(serverAddress!);
    if (match == null) return null;

    final ip = match.group(1);
    if (ip == null) return null;

    final parts = ip.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final segment = _extractNetworkSegment();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (segment != null) _chip(segment),
        _chip('192.168.1.1'),
        _chip('10.0.0.1'),
      ],
    );
  }

  Widget _chip(String ip) {
    return ActionChip(
      label: Text(ip, style: const TextStyle(fontSize: 12)),
      onPressed: isEnabled ? () => onIPSelected(ip) : null,
      backgroundColor: HomeUi.chipFill,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
