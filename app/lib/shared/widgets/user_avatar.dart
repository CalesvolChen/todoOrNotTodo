import 'package:flutter/material.dart';

import 'package:todo_app/core/network/file_url.dart';

/// 用户头像：加载失败或路径为空时显示姓名首字母占位。
class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    this.avatar,
    required this.name,
    this.radius = 20,
  });

  final String? avatar;
  final String name;
  final double radius;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  var _imageFailed = false;

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatar != widget.avatar) {
      _imageFailed = false;
      final oldUrl = fileUrl(oldWidget.avatar);
      if (oldUrl.isNotEmpty) {
        NetworkImage(oldUrl).evict();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = fileUrl(widget.avatar);
    final showFallback = url.isEmpty || _imageFailed;
    final initial = widget.name.characters.isNotEmpty
        ? widget.name.characters.first.toUpperCase()
        : '?';

    return CircleAvatar(
      key: showFallback ? null : ValueKey(url),
      radius: widget.radius,
      backgroundImage: showFallback ? null : NetworkImage(url),
      onBackgroundImageError: showFallback
          ? null
          : (_, __) {
              if (mounted) setState(() => _imageFailed = true);
            },
      child: showFallback
          ? Text(
              initial,
              style: TextStyle(fontSize: widget.radius * 0.9),
            )
          : null,
    );
  }
}
