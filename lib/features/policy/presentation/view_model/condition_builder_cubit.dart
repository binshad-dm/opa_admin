import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/condition_tree_entity.dart';
import '../../domain/entities/field_definition_entity.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/usecases/get_fields_usecase.dart';
import '../../domain/utils/policy_validators.dart';
import 'condition_builder_state.dart';

class ConditionBuilderCubit extends Cubit<ConditionBuilderState> {
  final GetFieldsUseCase getFieldsUseCase;

  ConditionBuilderCubit({
    required this.getFieldsUseCase,
  }) : super(const ConditionBuilderState(permissionCode: ''));

  void init(String permissionCode, PolicyEntity? policy) {
    ConditionGroupEntity tree = const ConditionGroupEntity(operator: 'AND', children: []);

    if (policy?.expressionJson != null && policy!.expressionJson!.isNotEmpty) {
      try {
        final node = ConditionNodeEntity.fromJson(policy.expressionJson!);
        if (node is ConditionGroupEntity) {
          tree = node;
        } else {
          tree = ConditionGroupEntity(operator: 'AND', children: [node]);
        }
      } catch (_) {}
    }

    emit(ConditionBuilderState(
      permissionCode: permissionCode,
      useCustomRego: policy?.useCustomRego ?? false,
      customRegoSnippet: policy?.customRegoSnippet ?? '',
      expressionTree: tree,
      isLoadingFields: true,
    ));

    loadFields(permissionCode);
  }

  Future<void> loadFields(String permissionCode) async {
    final result = await getFieldsUseCase(permissionCode);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingFields: false,
        error: failure.message,
      )),
      (fields) => emit(state.copyWith(
        fields: List<FieldDefinitionEntity>.from(fields),
        isLoadingFields: false,
      )),
    );
  }

  void setUseCustomRego(bool val) {
    emit(state.copyWith(useCustomRego: val));
  }

  void setCustomRegoSnippet(String snippet) {
    emit(state.copyWith(customRegoSnippet: snippet));
  }

  void updateTree(ConditionGroupEntity newTree) {
    emit(state.copyWith(expressionTree: newTree));
  }

  String generatePreview([ConditionNodeEntity? node, int depth = 0, bool isRoot = true]) {
    final current = node ?? state.expressionTree;
    final indent = '  ' * depth;

    if (current is ConditionGroupEntity) {
      if (current.children.isEmpty) return '$indent(Empty Group)';

      final childDepth = isRoot ? depth : depth + 1;
      final childPreviews = current.children
          .map((c) => generatePreview(c, childDepth, false))
          .where((s) => s.isNotEmpty)
          .toList();

      if (childPreviews.isEmpty) return '$indent(Empty Group)';
      if (childPreviews.length == 1) {
        if (current.operator == 'NOT') {
          return '$indent${current.operator} (${childPreviews.first.trim()})';
        }
        return generatePreview(current.children.first, depth, isRoot);
      }

      final childIndent = '  ' * childDepth;
      final joiner = '\n$childIndent${current.operator}\n';

      if (isRoot) {
        return childPreviews.join(joiner);
      } else {
        if (current.operator == 'NOT') {
          return '$indent${current.operator} (\n${childPreviews.join(joiner)}\n$indent)';
        }
        return '$indent(\n${childPreviews.join(joiner)}\n$indent)';
      }
    } else if (current is ConditionRuleEntity) {
      final fieldDef = state.fields.firstWhere(
        (f) => f.fieldName == current.field,
        orElse: () => FieldDefinitionEntity(
          fieldName: current.field,
          displayName: current.field.isEmpty ? 'Unknown Field' : current.field,
          fieldType: 'STRING',
        ),
      );

      final vType = current.valueType;
      String valStr = '';

      if (vType == 'FIELD') {
        valStr = '${current.value ?? ''} (Field)';
      } else if (vType == 'FIELD_LIST') {
        valStr = '${current.value ?? ''} (Field List)';
      } else if (current.value is List) {
        final list = (current.value as List)
            .where((v) => v.toString().isNotEmpty)
            .map((v) => '"$v"')
            .join(', ');
        valStr = '[$list]';
      } else if (current.value is String) {
        valStr = '"${current.value}"';
      } else if (current.value == null) {
        valStr = 'null';
      } else {
        valStr = current.value.toString();
      }

      return '$indent${fieldDef.displayName} ${current.comparison} $valStr';
    }
    return '';
  }

  bool hasEmptyGroup([ConditionNodeEntity? node]) {
    final current = node ?? state.expressionTree;
    if (current is ConditionGroupEntity) {
      if (current.children.isEmpty) return true;
      for (final child in current.children) {
        if (hasEmptyGroup(child)) return true;
      }
    }
    return false;
  }

  String? validateTree([ConditionNodeEntity? node]) {
    final current = node ?? state.expressionTree;

    if (current is ConditionGroupEntity) {
      if (current.children.isEmpty) {
        return 'Empty group detected in preview section. Add rules or remove empty group.';
      }
      for (final child in current.children) {
        final err = validateTree(child);
        if (err != null) return err;
      }
    } else if (current is ConditionRuleEntity) {
      if (current.field.trim().isEmpty) {
        return 'Rule field cannot be empty.';
      }

      final fieldDef = state.fields.cast<FieldDefinitionEntity?>().firstWhere(
        (f) => f?.fieldName == current.field,
        orElse: () => null,
      );

      final val = current.value;
      final vType = current.valueType;

      if (vType == 'FIELD' || vType == 'FIELD_LIST') {
        final pathErr = PolicyValidators.validateFieldPath(val?.toString());
        if (pathErr != null) {
          return 'Field path for "${fieldDef?.displayName ?? current.field}": $pathErr';
        }
      } else {
        final isArrayOp = current.comparison == 'in' || current.comparison == 'not_in';
        if (isArrayOp) {
          final isNum = fieldDef?.fieldType == 'NUMBER';
          if (val is List) {
            if (val.isEmpty || val.every((e) => e.toString().trim().isEmpty)) {
              return 'At least one value is required for "${fieldDef?.displayName ?? current.field}".';
            }
            if (isNum) {
              for (final item in val) {
                if (num.tryParse(item.toString().trim()) == null) {
                  return 'All values for "${fieldDef?.displayName ?? current.field}" must be valid numbers.';
                }
              }
            }
          } else {
            final arrErr = PolicyValidators.validateArrayValues(val?.toString(), isNumeric: isNum);
            if (arrErr != null) {
              return 'Values for "${fieldDef?.displayName ?? current.field}": $arrErr';
            }
          }
        } else if (fieldDef?.fieldType == 'NUMBER') {
          final numErr = PolicyValidators.validateNumber(val?.toString(), fieldDef?.displayName ?? 'Number');
          if (numErr != null) return numErr;
        } else if (fieldDef?.fieldType == 'BOOLEAN') {
          if (val != true && val != false) {
            return 'Select a boolean value for "${fieldDef?.displayName ?? current.field}".';
          }
        } else {
          if (val == null || val.toString().trim().isEmpty) {
            return 'Value is required for "${fieldDef?.displayName ?? current.field}".';
          }
        }
      }
    }

    return null;
  }

  String? get validationError {
    if (state.useCustomRego) {
      return PolicyValidators.validateRegoSnippet(state.customRegoSnippet);
    }
    return validateTree();
  }

  bool get isValid => validationError == null;
}
