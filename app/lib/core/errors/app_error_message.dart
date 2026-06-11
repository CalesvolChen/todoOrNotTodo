import 'package:dio/dio.dart';

const String kAppInternalErrorMessage = '操作失败，请联系管理员';
const String kNetworkErrorMessage = '网络错误，请检查网络连接后重试';

/// 将异常转换为用户可见的提示文案
String messageFromError(Object error) {
  if (error is DioException) {
    if (_isNetworkError(error)) {
      return kNetworkErrorMessage;
    }
    final apiMessage = _readApiMessage(error);
    if (apiMessage != null) {
      return apiMessage;
    }
    final status = error.response?.statusCode;
    if (status != null) {
      return '请求失败（$status）';
    }
    return kNetworkErrorMessage;
  }
  return kAppInternalErrorMessage;
}

bool _isNetworkError(DioException error) {
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      (error.type == DioExceptionType.unknown && error.response == null);
}

String? _readApiMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is List) {
      final parts = message
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('\n');
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}
