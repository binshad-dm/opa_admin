import 'package:equatable/equatable.dart';

class RoleDtoEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String status;

  const RoleDtoEntity({
    required this.id,
    required this.name,
    this.description,
    required this.status,
  });

  @override
  List<Object?> get props => [id, name, description, status];
}
