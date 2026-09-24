class Role {
  const Role({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.permissions,
    required this.userCount,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: json['id'] as int,
        name: json['name'] as String,
        isSystem: json['is_system'] as bool,
        permissions: (json['permissions'] as List<dynamic>? ?? []).cast<String>(),
        userCount: json['user_count'] as int,
      );

  final int id;
  final String name;
  final bool isSystem;
  final List<String> permissions;
  final int userCount;
}
