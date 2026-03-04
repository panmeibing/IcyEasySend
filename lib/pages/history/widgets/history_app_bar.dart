import 'package:flutter/material.dart';

/// App bar widget for history page
class HistoryAppBar extends StatelessWidget {
  final bool hasHistory;
  final VoidCallback onClearHistory;

  const HistoryAppBar({
    super.key,
    required this.hasHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                '传输历史',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            if (hasHistory)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onClearHistory,
                  tooltip: '清除历史',
                  color: const Color(0xFF757575),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
