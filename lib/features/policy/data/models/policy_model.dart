import 'dart:convert';
import '../../domain/entities/policy_entity.dart';

class PolicyModel extends PolicyEntity {
  const PolicyModel({
    required super.permissionCode,
    required super.resourceName,
    required super.action,
    super.namespace,
    super.policyId,
    super.enabled,
    super.effect,
    super.expressionJson,
    super.useCustomRego,
    super.customRegoSnippet,
    super.disabledReason,
    super.isDeleted,
    super.deletedReason,
    super.deprecated,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    final permCode = json['permissionCode'] as String? ?? '';

    String resourceName = json['resourceName'] as String? ?? '';
    String action = json['action'] as String? ?? '';
    String? namespace = json['namespace'] as String?;

    if (permCode.isNotEmpty) {
      final parts = permCode.split(':');
      if (namespace == null && parts.isNotEmpty) {
        namespace = parts.first;
      }
      if (resourceName.isEmpty && parts.length >= 2) {
        resourceName = parts[parts.length - 2];
      }
      if (action.isEmpty && parts.isNotEmpty) {
        action = parts.last;
      }
    }

    Map<String, dynamic>? expressionMap;
    final rawExpr = json['expressionJson'];
    if (rawExpr is Map<String, dynamic>) {
      expressionMap = rawExpr;
    } else if (rawExpr is String && rawExpr.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawExpr);
        if (decoded is Map<String, dynamic>) {
          expressionMap = decoded;
        }
      } catch (_) {}
    }

    return PolicyModel(
      permissionCode: permCode,
      resourceName: resourceName,
      action: action,
      namespace: namespace,
      policyId: json['policyId']?.toString(),
      enabled: json['enabled'] as bool? ?? false,
      effect: json['effect'] as String? ?? 'ALLOW',
      expressionJson: expressionMap,
      useCustomRego: json['useCustomRego'] as bool? ?? false,
      customRegoSnippet: json['customRegoSnippet'] as String?,
      disabledReason: json['disabledReason'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedReason: json['deletedReason'] as String?,
      deprecated: json['deprecated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permissionCode': permissionCode,
      if (namespace != null) 'namespace': namespace,
      if (policyId != null) 'policyId': policyId,
      'effect': effect,
      'expressionJson': expressionJson,
      'enabled': enabled,
      'isDeleted': isDeleted,
      'deletedReason': deletedReason,
      'disabledReason': disabledReason,
      'deprecated': this.deprecated,
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
      namespace: entity.namespace,
      policyId: entity.policyId,
      enabled: entity.enabled,
      effect: entity.effect,
      expressionJson: entity.expressionJson,
      useCustomRego: entity.useCustomRego,
      customRegoSnippet: entity.customRegoSnippet,
      disabledReason: entity.disabledReason,
      isDeleted: entity.isDeleted,
      deletedReason: entity.deletedReason,
      deprecated: entity.deprecated,
    );
  }
}
