import 'package:flutter/material.dart';

import '../home/home_ui.dart';
import 'tv_widgets.dart';

class TvPairingBody extends StatelessWidget {
  final String title;
  final String headline;
  final String sas;
  final String hint;
  final String? countdown;
  final Widget? peerStatus;
  final bool allowBlock;
  final bool acceptEnabled;
  final bool focusReject;
  final String rejectLabel;
  final String acceptLabel;
  final String blockLabel;
  final VoidCallback onReject;
  final VoidCallback onAccept;
  final VoidCallback onBlock;

  const TvPairingBody({
    super.key,
    required this.title,
    required this.headline,
    required this.sas,
    required this.hint,
    required this.allowBlock,
    required this.acceptEnabled,
    required this.focusReject,
    required this.rejectLabel,
    required this.acceptLabel,
    required this.blockLabel,
    required this.onReject,
    required this.onAccept,
    required this.onBlock,
    this.countdown,
    this.peerStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        color: HomeUi.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      headline,
                      style: const TextStyle(fontSize: 20, color: HomeUi.ink),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sas,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: HomeUi.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 16,
                        color: HomeUi.inkMuted,
                        height: 1.35,
                      ),
                    ),
                    if (peerStatus != null) ...[
                      const SizedBox(height: 12),
                      peerStatus!,
                    ],
                    if (countdown != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        countdown!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: HomeUi.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvButton(
                    label: rejectLabel,
                    primary: focusReject,
                    autofocus: focusReject,
                    onPressed: onReject,
                  ),
                  const SizedBox(height: 12),
                  TvButton(
                    label: acceptLabel,
                    primary: !focusReject,
                    autofocus: !focusReject,
                    onPressed: acceptEnabled ? onAccept : null,
                  ),
                  if (allowBlock) ...[
                    const SizedBox(height: 12),
                    TvButton(label: blockLabel, onPressed: onBlock),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
