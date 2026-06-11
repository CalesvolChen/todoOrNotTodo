import 'package:flutter/material.dart';

/// 带入场与按压缩放动效的 FAB
class AnimatedFab extends StatefulWidget {
  const AnimatedFab({
    super.key,
    required this.onPressed,
    required this.child,
  })  : icon = null,
        label = null;

  const AnimatedFab.extended({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : child = null;

  final VoidCallback onPressed;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _press;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutBack,
    );
    _entranceScale = Tween<double>(begin: 0.6, end: 1).animate(curved);
    _entranceOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
    );
    _pressScale = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _press.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    await _press.forward();
    await _press.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final fab = widget.child != null
        ? FloatingActionButton(
            onPressed: _handlePress,
            child: widget.child,
          )
        : FloatingActionButton.extended(
            onPressed: _handlePress,
            icon: widget.icon!,
            label: widget.label!,
          );

    return FadeTransition(
      opacity: _entranceOpacity,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic),
        ),
        child: ScaleTransition(
          scale: _entranceScale,
          child: ScaleTransition(
            scale: _pressScale,
            child: fab,
          ),
        ),
      ),
    );
  }
}
