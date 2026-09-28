import 'package:equatable/equatable.dart';

class PolicyEntity extends Equatable {
  final String permissionCode;
  final String resourceName;
  final String action;
  final String? namespace;
  final String? policyId;
  final bool enabled;
  final String effect; // ALLOW or DENY
  final Map<String, dynamic>? expressionJson;
  final bool useCustomRego;
  final String? customRegoSnippet;
  final String? disabledReason;
  final bool isDeleted;
  final String? deletedReason;
  final bool deprecated;

  const PolicyEntity({
    required this.permissionCode,
    required this.resourceName,
    required this.action,
    this.namespace,
    this.policyId,
    this.enabled = false,
    this.effect = 'ALLOW',
    this.expressionJson,
    this.useCustomRego = false,
    this.customRegoSnippet,
    this.disabledReason,
    this.isDeleted = false,
    this.deletedReason,
    this.deprecated = false,
  });

  PolicyEntity copyWith({
    String? permissionCode,
    String? resourceName,
    String? action,
    String? namespace,
    String? policyId,
    bool? enabled,
    String? effect,
    Map<String, dynamic>? expressionJson,
    bool? useCustomRego,
    String? customRegoSnippet,
    String? disabledReason,
    bool? isDeleted,
    String? deletedReason,
    bool? deprecated,
  }) {
    return PolicyEntity(
      permissionCode: permissionCode ?? this.permissionCode,
      resourceName: resourceName ?? this.resourceName,
      action: action ?? this.action,
      namespace: namespace ?? this.namespace,
      policyId: policyId ?? this.policyId,
      enabled: enabled ?? this.enabled,
      effect: effect ?? this.effect,
      expressionJson: expressionJson ?? this.expressionJson,
      useCustomRego: useCustomRego ?? this.useCustomRego,
      customRegoSnippet: customRegoSnippet ?? this.customRegoSnippet,
      disabledReason: disabledReason ?? this.disabledReason,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedReason: deletedReason ?? this.deletedReason,
      deprecated: deprecated ?? this.deprecated,
    );
  }

  @override
  List<Object?> get props => [
        permissionCode,
        resourceName,
        action,
        namespace,
        policyId,
        enabled,
        effect,
        expressionJson,
        useCustomRego,
        customRegoSnippet,
        disabledReason,
        isDeleted,
        deletedReason,
        deprecated,
      ];
}
