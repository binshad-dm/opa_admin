import 'package:equatable/equatable.dart';

import '../../domain/entities/condition_tree_entity.dart';
import '../../domain/entities/field_definition_entity.dart';

class ConditionBuilderState extends Equatable {
  final String permissionCode;
  final List<FieldDefinitionEntity> fields;
  final bool useCustomRego;
  final String customRegoSnippet;
  final ConditionGroupEntity expressionTree;
  final bool isLoadingFields;
  final String? error;

  const ConditionBuilderState({
    required this.permissionCode,
    this.fields = const [],
    this.useCustomRego = false,
    this.customRegoSnippet = '',
    this.expressionTree = const ConditionGroupEntity(operator: 'AND', children: []),
    this.isLoadingFields = false,
    this.error,
  });

  ConditionBuilderState copyWith({
    String? permissionCode,
    List<FieldDefinitionEntity>? fields,
    bool? useCustomRego,
    String? customRegoSnippet,
    ConditionGroupEntity? expressionTree,
    bool? isLoadingFields,
    String? error,
  }) {
    return ConditionBuilderState(
      permissionCode: permissionCode ?? this.permissionCode,
      fields: fields ?? this.fields,
      useCustomRego: useCustomRego ?? this.useCustomRego,
      customRegoSnippet: customRegoSnippet ?? this.customRegoSnippet,
      expressionTree: expressionTree ?? this.expressionTree,
      isLoadingFields: isLoadingFields ?? this.isLoadingFields,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        permissionCode,
        fields,
        useCustomRego,
        customRegoSnippet,
        expressionTree,
        isLoadingFields,
        error,
      ];
}
