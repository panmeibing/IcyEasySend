import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../home/home_ui.dart';

/// Full-width row used by TV lists. Direction keys move focus; select activates.
class TvRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool autofocus;
  final bool selected;
  final FocusNode? focusNode;

  const TvRow({
    super.key,
    required this.title,
    this.subtitle,
    this.onPressed,
    this.autofocus = false,
    this.selected = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed,
      style: ButtonStyle(
        alignment: Alignment.centerLeft,
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 64)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return HomeUi.primarySoft;
          if (selected) return Colors.white;
          return Colors.white;
        }),
        foregroundColor: const WidgetStatePropertyAll(HomeUi.ink),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: HomeUi.primary, width: 3);
          }
          if (selected) {
            return const BorderSide(color: HomeUi.primary, width: 1.5);
          }
          return const BorderSide(color: HomeUi.borderSoft);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: HomeUi.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class TvButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool expand;
  final double minWidth;

  const TvButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
    this.autofocus = false,
    this.focusNode,
    this.expand = false,
    this.minWidth = 160,
  });

  @override
  Widget build(BuildContext context) {
    final size = expand ? const Size(double.infinity, 56) : Size(minWidth, 56);
    // One button type for both states. Flipping FilledButton and OutlinedButton
    // detaches the focused node, and the remote jumps back to the control that
    // had focus before this one (the history "All" filter).
    return OutlinedButton(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(size),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primary
            ? const WidgetStatePropertyAll(HomeUi.primary)
            : null,
        foregroundColor: primary
            ? const WidgetStatePropertyAll(Colors.white)
            : null,
        overlayColor: primary
            ? WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return Colors.transparent;
                }
                return null;
              })
            : null,
        side: primary
            ? WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return const BorderSide(color: Color(0xFF1B6EC2), width: 3);
                }
                return BorderSide.none;
              })
            : null,
      ),
      child: Text(label, maxLines: 1, softWrap: false),
    );
  }
}

/// Two actions. [primaryIsReject] puts the initial focus on the first button,
/// which the caller labels as the safe choice.
class TvChoiceDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  const TvChoiceDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
  });

  @override
  Widget build(BuildContext context) {
    // The button column must have a finite width. A Row gives non-flex
    // children an unbounded width, and cross-axis stretch then fails layout,
    // leaving only the modal barrier.
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 560, maxWidth: 840),
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
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: HomeUi.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 18,
                        color: HomeUi.inkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 180,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TvButton(
                      label: primaryLabel,
                      autofocus: true,
                      primary: true,
                      onPressed: onPrimary,
                    ),
                    const SizedBox(height: 12),
                    TvButton(label: secondaryLabel, onPressed: onSecondary),
                    if (tertiaryLabel != null && onTertiary != null) ...[
                      const SizedBox(height: 12),
                      TvButton(label: tertiaryLabel!, onPressed: onTertiary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One text field. Back closes without saving.
///
/// The remote's confirm key opens the keyboard. After the keyboard closes,
/// down moves to the save button and left/right moves between the buttons.
/// The key that opened the dialog cannot also submit it.
Future<String?> showTvTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  bool obscure = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _TvTextPrompt(
        title: title,
        label: label,
        initial: initial,
        obscure: obscure,
      );
    },
  );
}

class _TvTextPrompt extends StatefulWidget {
  final String title;
  final String label;
  final String initial;
  final bool obscure;

  const _TvTextPrompt({
    required this.title,
    required this.label,
    required this.initial,
    required this.obscure,
  });

  @override
  State<_TvTextPrompt> createState() => _TvTextPromptState();
}

class _TvTextPromptState extends State<_TvTextPrompt>
    with WidgetsBindingObserver {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  final FocusNode _fieldNode = FocusNode(debugLabel: 'tv-text-field');
  final FocusNode _cancelNode = FocusNode(debugLabel: 'tv-text-cancel');
  final FocusNode _okNode = FocusNode(debugLabel: 'tv-text-ok');

  /// Confirm is still down while the dialog is opening. Ignore that press so
  /// it cannot submit the new field and dismiss the dialog immediately.
  bool _armed = HardwareKeyboard.instance.logicalKeysPressed.isEmpty;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_armAfterOpenKey);
    _fieldNode.onKeyEvent = _onFieldKey;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_armAfterOpenKey);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _fieldNode.dispose();
    _cancelNode.dispose();
    _okNode.dispose();
    super.dispose();
  }

  bool _armAfterOpenKey(KeyEvent event) {
    if (event is KeyUpEvent &&
        HardwareKeyboard.instance.logicalKeysPressed.isEmpty) {
      _armed = true;
    }
    return false;
  }

  bool _isConfirmKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  /// Android keeps the text input connection after the keyboard closes, and
  /// that connection consumes d-pad keys. Handle them here first.
  KeyEventResult _onFieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _okNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.handled;
    }
    if (_isConfirmKey(event.logicalKey)) {
      if (_armed) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bottom = MediaQuery.viewInsetsOf(context).bottom;
      final visible = bottom > 0;
      final closed = _keyboardVisible && !visible;
      _keyboardVisible = visible;
      if (closed && _fieldNode.hasFocus) {
        _okNode.requestFocus();
      }
    });
  }

  void _cancel() {
    if (!_armed) return;
    Navigator.of(context).pop();
  }

  void _save() {
    if (!_armed) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10nCancel = MaterialLocalizations.of(context).cancelButtonLabel;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: HomeUi.ink,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _fieldNode,
                autofocus: true,
                obscureText: widget.obscure,
                style: const TextStyle(fontSize: 20),
                decoration: HomeUi.fieldDecoration(hintText: widget.label),
                textInputAction: TextInputAction.done,
                onEditingComplete: () {},
                onSubmitted: (_) {
                  if (_armed) _okNode.requestFocus();
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TvButton(
                    label: l10nCancel,
                    focusNode: _cancelNode,
                    onPressed: _cancel,
                  ),
                  const SizedBox(width: 12),
                  TvButton(
                    label: MaterialLocalizations.of(context).okButtonLabel,
                    primary: true,
                    focusNode: _okNode,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clipboard allow / deny. Initial focus and the back key both reject.
Future<bool> showTvClipboardConfirm(
  BuildContext context, {
  required String requesterDeviceName,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return TvChoiceDialog(
        title: l10n.clipboardRequest,
        message: l10n.clipboardRequestFrom(requesterDeviceName),
        primaryLabel: l10n.reject,
        secondaryLabel: l10n.allowClipboardRequest,
        onPrimary: () => Navigator.of(dialogContext).pop(false),
        onSecondary: () => Navigator.of(dialogContext).pop(true),
      );
    },
  ).then((value) => value ?? false);
}
