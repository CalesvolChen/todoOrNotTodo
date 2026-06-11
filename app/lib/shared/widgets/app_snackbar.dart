import 'package:flutter/material.dart';

enum AppSnackBarType { info, success, error }

/// 统一浮动 SnackBar：主题样式 + 内容入场动效
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: _AnimatedSnackBarBody(message: message, type: type),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

extension AppSnackBarContext on BuildContext {
  void showAppSnackBar(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: _AnimatedSnackBarBody(message: message, type: type),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _AnimatedSnackBarBody extends StatefulWidget {
  const _AnimatedSnackBarBody({
    required this.message,
    required this.type,
  });

  final String message;
  final AppSnackBarType type;

  @override
  State<_AnimatedSnackBarBody> createState() => _AnimatedSnackBarBodyState();
}

class _AnimatedSnackBarBodyState extends State<_AnimatedSnackBarBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconForType() {
    return switch (widget.type) {
      AppSnackBarType.success => Icons.check_circle_outline,
      AppSnackBarType.error => Icons.error_outline,
      AppSnackBarType.info => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Row(
          children: [
            Icon(_iconForType(), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.message)),
          ],
        ),
      ),
    );
  }
}
