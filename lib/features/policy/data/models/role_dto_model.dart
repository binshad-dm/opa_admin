import '../../domain/entities/role_dto_entity.dart';

class RoleDtoModel extends RoleDtoEntity {
  const RoleDtoModel({
    required super.id,
    required super.name,
    required super.status,
    super.description,
  });

  factory RoleDtoModel.fromJson(Map<String, dynamic> json) {
    return RoleDtoModel(
      id: (json['id'] ?? json['subjectId'] ?? json['name'] ?? '').toString(),
      name: (json['name'] ?? json['subjectName'] ?? json['displayName'] ?? '')
          .toString(),
      status: (json['status']).toString(),
      description: json['description'] as String?,
    );
  }
}
