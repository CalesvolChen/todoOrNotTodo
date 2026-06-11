class Invitation {
  Invitation({
    required this.id,
    required this.listId,
    required this.listName,
    required this.inviterName,
  });

  final String id;
  final String listId;
  final String listName;
  final String inviterName;

  factory Invitation.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as Map<String, dynamic>?;
    final inviter = json['inviter'] as Map<String, dynamic>?;
    return Invitation(
      id: json['id'] as String,
      listId: json['listId'] as String,
      listName: list?['name'] as String? ?? '分组',
      inviterName:
          inviter?['name'] as String? ?? inviter?['username'] as String? ?? '某用户',
    );
  }
}
