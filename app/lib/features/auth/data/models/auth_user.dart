class AuthUser {
  AuthUser({
    required this.id,
    this.email,
    this.username,
    this.name,
    this.avatar,
    required this.role,
  });

  final String id;
  final String? email;
  final String? username;
  final String? name;
  final String? avatar;
  final String role;

  String get displayName => name ?? username ?? email ?? '用户';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        username: json['username'] as String?,
        name: json['name'] as String?,
        avatar: json['avatar'] as String?,
        role: json['role'] as String? ?? 'USER',
      );

  AuthUser copyWith({String? name, String? avatar}) => AuthUser(
        id: id,
        email: email,
        username: username,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        role: role,
      );
}
