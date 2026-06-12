import 'package:todo_app/features/auth/data/models/auth_user.dart';

class GroupMember {
  GroupMember({
    required this.id,
    this.username,
    this.name,
    this.avatar,
  });

  final String id;
  final String? username;
  final String? name;
  final String? avatar;

  String get displayName => name ?? username ?? '用户';

  /// 当前登录用户优先使用 auth 中的最新头像与显示名。
  ({String? avatar, String displayName}) presentationFor(AuthUser? currentUser) {
    if (currentUser != null && currentUser.id == id) {
      return (avatar: currentUser.avatar, displayName: currentUser.displayName);
    }
    return (avatar: avatar, displayName: displayName);
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        username: json['username'] as String?,
        name: json['name'] as String?,
        avatar: json['avatar'] as String?,
      );
}

class GroupMembers {
  GroupMembers({required this.owner, required this.members});

  final GroupMember owner;
  final List<GroupMember> members;

  factory GroupMembers.fromJson(Map<String, dynamic> json) => GroupMembers(
        owner: GroupMember.fromJson(json['owner'] as Map<String, dynamic>),
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
