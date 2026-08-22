import 'package:equatable/equatable.dart';

class PolicyEntity extends Equatable {
  final String permissionCode;
  final String resourceName;
  final String action;
  final bool enabled;
  final String effect; // ALLOW or DENY
  final Map<String, dynamic>? expressionJson;
  final bool useCustomRego;
  final String? customRegoSnippet;
  final String? disabledReason;
  final bool isDeleted;
  final String? deletedReason;

  const PolicyEntity({
    required this.permissionCode,
    required this.resourceName,
    required this.action,
    this.enabled = false,
    this.effect = 'ALLOW',
    this.expressionJson,
    this.useCustomRego = false,
    this.customRegoSnippet,
    this.disabledReason,
    this.isDeleted = false,
    this.deletedReason,
  });

  PolicyEntity copyWith({
    String? permissionCode,
    String? resourceName,
    String? action,
    bool? enabled,
    String? effect,
    Map<String, dynamic>? expressionJson,
    bool? useCustomRego,
    String? customRegoSnippet,
    String? disabledReason,
    bool? isDeleted,
    String? deletedReason,
  }) {
    return PolicyEntity(
      permissionCode: permissionCode ?? this.permissionCode,
      resourceName: resourceName ?? this.resourceName,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
      effect: effect ?? this.effect,
      expressionJson: expressionJson ?? this.expressionJson,
      useCustomRego: useCustomRego ?? this.useCustomRego,
      customRegoSnippet: customRegoSnippet ?? this.customRegoSnippet,
      disabledReason: disabledReason ?? this.disabledReason,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedReason: deletedReason ?? this.deletedReason,
    );
  }

  @override
  List<Object?> get props => [
        permissionCode,
        resourceName,
        action,
        enabled,
        effect,
        expressionJson,
        useCustomRego,
        customRegoSnippet,
        disabledReason,
        isDeleted,
        deletedReason,
      ];
}
