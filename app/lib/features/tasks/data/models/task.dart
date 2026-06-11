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
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.note,
    required this.completed,
    required this.important,
    this.dueDate,
    this.steps = const [],
  });

  final String id;
  final String title;
  final String? note;
  final bool completed;
  final bool important;
  final DateTime? dueDate;
  final List<TaskStep> steps;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        note: json['note'] as String?,
        completed: json['completed'] as bool? ?? false,
        important: json['important'] as bool? ?? false,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((e) => TaskStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
