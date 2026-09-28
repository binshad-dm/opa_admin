import 'package:equatable/equatable.dart';

class UserDtoEntity extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String status;

  const UserDtoEntity({
    required this.id,
    required this.email,
    required this.status,
    this.firstName,
    this.lastName,
  });

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      final last = lastName ?? '';
      return '$firstName $last ($email)'.trim();
    }
    return email;
  }

  bool get isActive {
    return status.toLowerCase() == 'ACTIVE';
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, status];
}
