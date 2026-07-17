import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/theme.dart';

/// Toast nhỏ gọn trượt xuống từ mép trên, tự ẩn sau vài giây - thay cho
/// [SnackBar] mặc định (nền xám vuông dính đáy, không hợp phong cách
/// pill/bo tròn của app) và không che khuất nút Checkout hay bottom nav.
class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastEntry(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismissed: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _ToastEntry extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastEntry({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastEntry> createState() => _ToastEntryState();
}

class _ToastEntryState extends State<_ToastEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onDismissed();
    });
    _controller.forward();
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: _offset,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => _controller.reverse(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (widget.actionLabel != null && widget.onAction != null) ...[
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {
                              widget.onAction!();
                              _controller.reverse();
                            },
                            child: Text(
                              widget.actionLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
