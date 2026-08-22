import '../../domain/entities/dynamic_option_entity.dart';

class DynamicOptionModel extends DynamicOptionEntity {
  const DynamicOptionModel({
    required super.id,
    required super.displayName,
  });

  factory DynamicOptionModel.fromJson(Map<String, dynamic> json) {
    return DynamicOptionModel(
      id: (json['id'] ?? json['code'] ?? json['value'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? json['label'] ?? json['id'] ?? '').toString(),
    );
  }
}
