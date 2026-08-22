import 'package:equatable/equatable.dart';

class UserDtoEntity extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  const UserDtoEntity({
    required this.id,
    required this.email,
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

  @override
  List<Object?> get props => [id, email, firstName, lastName];
}
