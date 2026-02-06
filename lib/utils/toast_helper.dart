import 'package:flutter/material.dart';

/// Toast 工具类 - 提供顶层提示消息，不会被 Dialog 等组件遮挡
class ToastHelper {
  static OverlayEntry? _currentToast;
  static bool _isShowing = false;

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red,
      duration: duration,
    );
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.blue,
      duration: duration,
    );
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: Colors.orange,
      duration: duration,
    );
  }

  /// 显示普通提示
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
    Color? backgroundColor,
  }) {
    _showToast(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor ?? Colors.black87,
      duration: duration,
    );
  }

  /// 内部方法：显示 Toast
  static void _showToast(
    BuildContext context, {
    required String message,
    IconData? icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    // 如果已经有 Toast 在显示，先移除
    if (_isShowing) {
      _removeToast();
    }

    _isShowing = true;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
      ),
    );

    _currentToast = overlayEntry;
    overlay.insert(overlayEntry);

    // 自动移除
    Future.delayed(duration, () {
      _removeToast();
    });
  }

  /// 移除当前显示的 Toast
  static void _removeToast() {
    _currentToast?.remove();
    _currentToast = null;
    _isShowing = false;
  }

  /// 手动隐藏 Toast
  static void hide() {
    _removeToast();
  }
}

/// Toast 显示组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color backgroundColor;

  const _ToastWidget({
    required this.message,
    this.icon,
    required this.backgroundColor,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
