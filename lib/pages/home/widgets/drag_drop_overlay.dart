import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../home_ui.dart';

/// Full-screen overlay shown while dragging files onto the home page.
class DragDropOverlay extends StatelessWidget {
  const DragDropOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: HomeUi.primary.withValues(alpha: 0.08),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(HomeUi.radiusLg),
              border: Border.all(color: HomeUi.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: HomeUi.ink.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.file_download_rounded,
                  size: 56,
                  color: HomeUi.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).releaseToAdd,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: HomeUi.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
