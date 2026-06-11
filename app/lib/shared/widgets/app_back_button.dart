import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 二级页面统一返回按钮：优先 pop，无法 pop 时回到首页
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackLocation = '/',
    this.onPressed,
  });

  final String fallbackLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      tooltip: '返回',
      onPressed: onPressed ?? () => _goBack(context),
    );
  }

  void _goBack(BuildContext context) =>
      safeGoBack(context, fallbackLocation: fallbackLocation);
}

/// 安全返回：有历史则 pop，否则 go 到 fallback（避免 go_router 无栈可 pop 报错）
void safeGoBack(BuildContext context, {String fallbackLocation = '/'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackLocation);
  }
}

/// 带返回按钮的 AppBar，供二级页面复用
PreferredSizeWidget secondaryAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  String fallbackLocation = '/',
}) {
  return AppBar(
    leading: AppBackButton(fallbackLocation: fallbackLocation),
    title: Text(title),
    actions: actions,
  );
}
