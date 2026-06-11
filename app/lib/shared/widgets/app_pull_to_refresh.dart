import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 列表常用滚动物理：短列表也可下拉，带回弹
const ScrollPhysics kAppListScrollPhysics = AlwaysScrollableScrollPhysics(
  parent: BouncingScrollPhysics(),
);

/// 统一的下拉刷新：主题样式 + 下拉/完成时轻微震动
class AppPullToRefresh extends StatefulWidget {
  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// 将空状态包成可下拉刷新的可滚动区域
  static Widget scrollableEmpty({
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: kAppListScrollPhysics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AppPullToRefresh> createState() => _AppPullToRefreshState();
}

class _AppPullToRefreshState extends State<AppPullToRefresh>
    with SingleTickerProviderStateMixin {
  bool _pullHapticFired = false;
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    _pulse.repeat(reverse: true);
    try {
      await widget.onRefresh();
    } finally {
      _pulse.stop();
      _pulse.reset();
      if (mounted) {
        HapticFeedback.lightImpact();
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels < -48 && !_pullHapticFired) {
        _pullHapticFired = true;
        HapticFeedback.selectionClick();
      }
    } else if (notification is ScrollEndNotification) {
      _pullHapticFired = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          RefreshIndicator(
            elevation: 3,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.primary,
            strokeWidth: 2.5,
            displacement: 52,
            edgeOffset: 12,
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: _handleRefresh,
            child: widget.child,
          ),
          Positioned(
            top: 8,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  if (!_pulse.isAnimating) return const SizedBox.shrink();
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: Icon(
                      Icons.autorenew_rounded,
                      size: 18,
                      color: scheme.primary.withValues(alpha: 0.45),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
