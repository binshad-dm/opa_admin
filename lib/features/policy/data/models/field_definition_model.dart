import '../../domain/entities/field_definition_entity.dart';

class FieldDefinitionModel extends FieldDefinitionEntity {
  const FieldDefinitionModel({
    required super.fieldName,
    required super.displayName,
    required super.fieldType,
    super.allowedValues,
    super.optionsEndpoint,
  });

  factory FieldDefinitionModel.fromJson(Map<String, dynamic> json) {
    List<String>? allowed;
    if (json['allowedValues'] != null) {
      allowed = (json['allowedValues'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return FieldDefinitionModel(
      fieldName: json['fieldName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['fieldName'] as String? ?? '',
      fieldType: json['fieldType'] as String? ?? 'STRING',
      allowedValues: allowed,
      optionsEndpoint: json['optionsEndpoint'] as String?,
    );
  }
}
