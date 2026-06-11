import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// 跨平台构造 multipart 文件（Web 不支持 fromFile，需读 bytes）。
Future<MultipartFile> buildMultipartFile({
  required String filename,
  required DioMediaType contentType,
  XFile? xFile,
  String? filePath,
  List<int>? bytes,
}) async {
  if (xFile != null) {
    final data = await xFile.readAsBytes();
    final name = xFile.name.isNotEmpty ? xFile.name : filename;
    return MultipartFile.fromBytes(
      data,
      filename: name,
      contentType: contentType,
    );
  }

  if (bytes != null) {
    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  if (filePath != null && !kIsWeb) {
    return MultipartFile.fromFile(
      filePath,
      filename: filename,
      contentType: contentType,
    );
  }

  throw ArgumentError('无法构造上传文件：Web 端请使用 XFile 或 bytes');
}

DioMediaType guessImageMediaType(String? mime, String pathOrName) {
  if (mime != null && mime.isNotEmpty) {
    return DioMediaType.parse(mime);
  }
  final lower = pathOrName.toLowerCase();
  if (lower.endsWith('.png')) return DioMediaType('image', 'png');
  if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
  if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
  return DioMediaType('image', 'jpeg');
}
