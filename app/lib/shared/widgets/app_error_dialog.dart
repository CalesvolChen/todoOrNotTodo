import 'package:flutter/material.dart';

import 'package:todo_app/core/errors/app_error_message.dart';

/// 展示操作失败弹窗
Future<void> showAppErrorDialog(
  BuildContext context, {
  Object? error,
  String? message,
}) {
  assert(error != null || message != null);
  final text = message ?? messageFromError(error!);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('操作失败'),
      content: Text(text),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

/// 执行异步操作，失败时弹出统一错误提示。成功返回 true，失败返回 false。
Future<bool> runWithAppErrorDialog(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error, stackTrace) {
    debugPrint('Operation failed: $error\n$stackTrace');
    if (context.mounted) {
      await showAppErrorDialog(context, error: error);
    }
    return false;
  }
}
