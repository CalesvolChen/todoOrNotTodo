import 'package:todo_app/core/constants/app_constants.dart';

/// 把后端返回的相对文件路径（/uploads/...）拼成绝对 URL。
/// 去掉 apiBaseUrl 末尾的 /api 前缀，得到文件服务源。
String fileUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final origin =
      AppConstants.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$origin$path';
}
