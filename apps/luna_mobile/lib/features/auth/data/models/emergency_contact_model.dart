import '../../domain/entities/emergency_contact_entity.dart';

class EmergencyContactModel extends EmergencyContactEntity {
  const EmergencyContactModel({
    required super.id,
    required super.name,
    required super.relationship,
    required super.phone,
    super.isPrimary = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isPrimary: json['is_primary'] ?? json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'is_primary': isPrimary,
    };
  }

  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phone,
    bool? isPrimary,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
