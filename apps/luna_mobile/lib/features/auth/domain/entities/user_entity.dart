class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? bio;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.bio,
  });
}
