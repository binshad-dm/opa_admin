import '../../domain/entities/policy_entity.dart';

class PolicyModel extends PolicyEntity {
  const PolicyModel({
    required super.permissionCode,
    required super.resourceName,
    required super.action,
    super.enabled,
    super.effect,
    super.expressionJson,
    super.useCustomRego,
    super.customRegoSnippet,
    super.disabledReason,
    super.isDeleted,
    super.deletedReason,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    final permCode = json['permissionCode'] as String? ?? '';

    String resourceName = json['resourceName'] as String? ?? '';
    String action = json['action'] as String? ?? '';

    if (permCode.isNotEmpty) {
      final parts = permCode.split(':');
      if (resourceName.isEmpty && parts.length >= 2) {
        resourceName = parts[parts.length - 2];
      }
      if (action.isEmpty && parts.isNotEmpty) {
        action = parts.last;
      }
    }

    return PolicyModel(
      permissionCode: permCode,
      resourceName: resourceName,
      action: action,
      enabled: json['enabled'] as bool? ?? false,
      effect: json['effect'] as String? ?? 'ALLOW',
      expressionJson: json['expressionJson'] as Map<String, dynamic>?,
      useCustomRego: json['useCustomRego'] as bool? ?? false,
      customRegoSnippet: json['customRegoSnippet'] as String?,
      disabledReason: json['disabledReason'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedReason: json['deletedReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permissionCode': permissionCode,
      'effect': effect,
      'expressionJson': expressionJson,
      'enabled': enabled,
      'isDeleted': isDeleted,
      'deletedReason': deletedReason,
      'disabledReason': disabledReason,
      'useCustomRego': useCustomRego,
      'customRegoSnippet':
          (customRegoSnippet == null || customRegoSnippet!.isEmpty)
              ? null
              : customRegoSnippet,
    };
  }

  factory PolicyModel.fromEntity(PolicyEntity entity) {
    return PolicyModel(
      permissionCode: entity.permissionCode,
      resourceName: entity.resourceName,
      action: entity.action,
      enabled: entity.enabled,
      effect: entity.effect,
      expressionJson: entity.expressionJson,
      useCustomRego: entity.useCustomRego,
      customRegoSnippet: entity.customRegoSnippet,
      disabledReason: entity.disabledReason,
      isDeleted: entity.isDeleted,
      deletedReason: entity.deletedReason,
    );
  }
}
