import 'package:equatable/equatable.dart';

class FieldDefinitionEntity extends Equatable {
  final String fieldName;
  final String displayName;
  final String fieldType; // STRING, NUMBER, BOOLEAN, etc.
  final List<String>? allowedValues;
  final String? optionsEndpoint;

  const FieldDefinitionEntity({
    required this.fieldName,
    required this.displayName,
    required this.fieldType,
    this.allowedValues,
    this.optionsEndpoint,
  });

  @override
  List<Object?> get props => [
        fieldName,
        displayName,
        fieldType,
        allowedValues,
        optionsEndpoint,
      ];
}
