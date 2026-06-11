class AuthUser {
  AuthUser({required this.id, required this.email, required this.role});

  final String id;
  final String email;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'USER',
      );
}
