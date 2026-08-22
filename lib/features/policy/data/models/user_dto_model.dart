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
      id: (json['id'] ?? json['email']).toString(),
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }
}
