import 'package:equatable/equatable.dart';

class DynamicOptionEntity extends Equatable {
  final String id;
  final String displayName;

  const DynamicOptionEntity({
    required this.id,
    required this.displayName,
  });

  @override
  List<Object?> get props => [id, displayName];
}
