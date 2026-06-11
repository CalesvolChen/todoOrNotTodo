import 'package:todo_app/features/tasks/data/models/attachment.dart';

class TaskStep {
  TaskStep({required this.id, required this.title, required this.completed});

  final String id;
  final String title;
  final bool completed;

  factory TaskStep.fromJson(Map<String, dynamic> json) => TaskStep(
        id: json['id'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool? ?? false,
      );

  TaskStep copyWith({bool? completed}) => TaskStep(
        id: id,
        title: title,
        completed: completed ?? this.completed,
      );
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.note,
    required this.completed,
    this.completedAt,
    required this.important,
    this.dueDate,
    this.listId,
    this.createdAt,
    this.steps = const [],
    this.attachments = const [],
  });

  final String id;
  final String title;
  final String? note;
  final bool completed;
  final DateTime? completedAt;
  final bool important;
  final DateTime? dueDate;
  final String? listId;
  final DateTime? createdAt;
  final List<TaskStep> steps;
  final List<Attachment> attachments;

  List<Attachment> get images =>
      attachments.where((a) => a.kind == AttachmentKind.image).toList();
  List<Attachment> get audios =>
      attachments.where((a) => a.kind == AttachmentKind.audio).toList();

  /// 步骤进度文案，无步骤时返回 null
  String? get stepProgressLabel {
    if (steps.isEmpty) return null;
    final total = steps.length;
    final done = steps.where((s) => s.completed).length;
    if (done >= total) return '第 $total 步，共 $total 步';
    return '第 ${done + 1} 步，共 $total 步';
  }

  static const _unset = Object();

  Task copyWith({
    String? title,
    String? note,
    bool? completed,
    Object? completedAt = _unset,
    bool? important,
    Object? listId = _unset,
    List<TaskStep>? steps,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        completed: completed ?? this.completed,
        completedAt: identical(completedAt, _unset)
            ? this.completedAt
            : completedAt as DateTime?,
        important: important ?? this.important,
        dueDate: dueDate,
        listId: identical(listId, _unset) ? this.listId : listId as String?,
        createdAt: createdAt,
        steps: steps ?? this.steps,
        attachments: attachments,
      );

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        note: json['note'] as String?,
        completed: json['completed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        important: json['important'] as bool? ?? false,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        listId: json['listId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((e) => TaskStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        attachments: (json['attachments'] as List<dynamic>? ?? [])
            .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 将任务拆分为进行中与已完成
({List<Task> active, List<Task> completed}) splitTasksByCompletion(
  List<Task> tasks,
) {
  final active = <Task>[];
  final completed = <Task>[];
  for (final t in tasks) {
    (t.completed ? completed : active).add(t);
  }
  completed.sort((a, b) {
    final at = a.completedAt ?? a.createdAt;
    final bt = b.completedAt ?? b.createdAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });
  return (active: active, completed: completed);
}
