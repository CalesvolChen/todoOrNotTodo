class TaskList {
  TaskList({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.ownerId,
    this.ownerName,
    this.memberCount = 0,
    this.taskCount = 0,
  });

  final String id;
  final String name;
  final bool isDefault;
  final String ownerId;
  final String? ownerName;
  final int memberCount;
  final int taskCount;

  /// 是否为共享分组（有其他成员加入）
  bool get isShared => memberCount > 0;

  factory TaskList.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;
    return TaskList(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      ownerId: json['ownerId'] as String? ?? (owner?['id'] as String? ?? ''),
      ownerName: owner?['name'] as String? ?? owner?['username'] as String?,
      memberCount: count?['members'] as int? ?? 0,
      taskCount: count?['tasks'] as int? ?? 0,
    );
  }
}
