import '../../domain/entities/user_dto_entity.dart';

class UserDtoModel extends UserDtoEntity {
  const UserDtoModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
  });

  factory UserDtoModel.fromJson(Map<String, dynamic> json) {
    return UserDtoModel(
      id: (json['id'] ?? json['subjectId'] ?? json['email'] ?? '').toString(),
      email: (json['email'] ?? json['subjectName'] ?? '').toString(),
      firstName: (json['firstName'] ?? json['displayName']) as String?,
      lastName: json['lastName'] as String?,
    );
  }
}
