enum AttachmentKind { image, audio, other }

class Attachment {
  Attachment({
    required this.id,
    required this.kind,
    required this.path,
    required this.mime,
    required this.size,
    required this.fileName,
  });

  final String id;
  final AttachmentKind kind;
  final String path;
  final String mime;
  final int size;
  final String fileName;

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String,
        kind: _parseKind(json['kind'] as String?),
        path: json['path'] as String? ?? '',
        mime: json['mime'] as String? ?? '',
        size: json['size'] as int? ?? 0,
        fileName: json['fileName'] as String? ?? '',
      );

  static AttachmentKind _parseKind(String? k) {
    switch (k) {
      case 'IMAGE':
        return AttachmentKind.image;
      case 'AUDIO':
        return AttachmentKind.audio;
      default:
        return AttachmentKind.other;
    }
  }
}
