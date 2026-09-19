class EmergencyContactEntity {
  final String id;
  final String name;
  final String relationship;
  final String phone;
  final bool isPrimary;

  const EmergencyContactEntity({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.isPrimary = false,
  });
}
