import 'package:flutter/material.dart';

import 'package:todo_app/core/network/file_url.dart';

/// 网络图片：404 或加载失败时显示占位图。
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.broken_image_outlined,
  });

  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final url = fileUrl(path);
    Widget child;

    if (url.isEmpty) {
      child = _placeholder(context);
    } else {
      child = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
