import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/condition_tree_entity.dart';
import '../../domain/entities/field_definition_entity.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/usecases/get_fields_usecase.dart';
import '../../domain/utils/policy_validators.dart';
import 'condition_builder_state.dart';

class ConditionBuilderCubit extends Cubit<ConditionBuilderState> {
  final GetFieldsUseCase getFieldsUseCase;

  ConditionBuilderCubit({required this.getFieldsUseCase})
    : super(const ConditionBuilderState(permissionCode: ''));

  void init(String permissionCode, PolicyEntity? policy) {
    ConditionGroupEntity tree = const ConditionGroupEntity(
      operator: 'AND',
      children: [],
    );

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

    emit(
      ConditionBuilderState(
        permissionCode: permissionCode,
        useCustomRego: policy?.useCustomRego ?? false,
        customRegoSnippet: policy?.customRegoSnippet ?? '',
        expressionTree: tree,
        isLoadingFields: true,
      ),
    );

    loadFields(permissionCode);
  }

  Future<void> loadFields(String permissionCode) async {
    final result = await getFieldsUseCase(permissionCode);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingFields: false, error: failure.message)),
      (fields) => emit(
        state.copyWith(
          fields: List<FieldDefinitionEntity>.from(fields),
          isLoadingFields: false,
        ),
      ),
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

  void clearConditions() {
    emit(
      state.copyWith(
        expressionTree: const ConditionGroupEntity(
          operator: 'AND',
          children: [],
        ),
        useCustomRego: false,
        customRegoSnippet: '',
      ),
    );
  }

  bool hasRules([ConditionNodeEntity? node]) {
    final current = node ?? state.expressionTree;
    if (current is ConditionRuleEntity) {
      return current.field.trim().isNotEmpty;
    } else if (current is ConditionGroupEntity) {
      for (final child in current.children) {
        if (hasRules(child)) return true;
      }
    }
    return false;
  }

  String generatePreview([
    ConditionNodeEntity? node,
    int depth = 0,
    bool isRoot = true,
  ]) {
    final current = node ?? state.expressionTree;
    final indent = '  ' * depth;

    if (current is ConditionGroupEntity) {
      if (current.children.isEmpty) {
        if (isRoot) return 'No conditions configured.';
        return '$indent(Empty Group)';
      }

      final childDepth = isRoot ? depth : depth + 1;
      final childPreviews = current.children
          .map((c) => generatePreview(c, childDepth, false))
          .where((s) => s.isNotEmpty)
          .toList();

      if (childPreviews.isEmpty) {
        if (isRoot) return 'No conditions configured.';
        return '$indent(Empty Group)';
      }

      // Deduplicate duplicate empty group previews so only configured groups are shown
      final distinctPreviews = <String>[];
      for (final cp in childPreviews) {
        if (cp.trim() == '(Empty Group)' &&
            distinctPreviews.any((e) => e.trim() == '(Empty Group)')) {
          continue;
        }
        distinctPreviews.add(cp);
      }

      if (distinctPreviews.length == 1) {
        if (current.operator == 'NOT') {
          return '$indent${current.operator} (${distinctPreviews.first.trim()})';
        }
        return distinctPreviews.first;
      }

      final childIndent = '  ' * childDepth;
      final joiner = '\n$childIndent${current.operator}\n';

      if (isRoot) {
        return distinctPreviews.join(joiner);
      } else {
        if (current.operator == 'NOT') {
          return '$indent${current.operator} (\n${distinctPreviews.join(joiner)}\n$indent)';
        }
        return '$indent(\n${distinctPreviews.join(joiner)}\n$indent)';
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

      if (vType == 'MATH_EXPRESSION') {
        String mathStr = fieldDef.displayName;
        if (current.mathOperations != null &&
            current.mathOperations!.isNotEmpty) {
          for (final op in current.mathOperations!) {
            final opSym = op.mathOperator == 'MULTIPLY'
                ? '*'
                : op.mathOperator == 'DIVIDE'
                ? '/'
                : op.mathOperator == 'SUBTRACT'
                ? '-'
                : '+';
            final opVal = op.operandType == 'FIELD'
                ? '${op.value} (Field)'
                : op.value;
            mathStr = '($mathStr $opSym $opVal)';
          }
        }
        final targetStr = current.compareTo == 'FIELD'
            ? '${current.value ?? ''} (Field)'
            : '"${current.value ?? ''}"';
        return '$indent$mathStr ${current.comparison} $targetStr';
      }

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

  bool hasEmptyGroup([ConditionNodeEntity? node, bool isRoot = true]) {
    final current = node ?? state.expressionTree;
    if (current is ConditionGroupEntity) {
      if (current.children.isEmpty) {
        // Root with no children is simply an unconditional policy, not an empty group defect
        return !isRoot;
      }
      for (final child in current.children) {
        if (hasEmptyGroup(child, false)) return true;
      }
    }
    return false;
  }

  String? validateTree([ConditionNodeEntity? node, bool isRoot = true]) {
    final current = node ?? state.expressionTree;

    if (current is ConditionGroupEntity) {
      if (current.children.isEmpty) {
        if (isRoot)
          return null; // Root without children is a valid empty condition
        return 'Empty group detected in preview section. Add rules or remove empty group.';
      }
      for (final child in current.children) {
        final err = validateTree(child, false);
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

      if (vType == 'MATH_EXPRESSION') {
        if (current.mathOperations != null) {
          for (int i = 0; i < current.mathOperations!.length; i++) {
            final op = current.mathOperations![i];
            final opIndex = i + 1;
            if (op.operandType == 'FIELD') {
              final pathErr = PolicyValidators.validateFieldPath(op.value);
              if (pathErr != null) {
                return 'Math Op #$opIndex field path: $pathErr';
              }
            } else {
              if (op.value.trim().isEmpty) {
                return 'Math Op #$opIndex value is required.';
              }
              if (num.tryParse(op.value.trim()) == null) {
                return 'Math Op #$opIndex value must be a valid number.';
              }
              if (op.mathOperator == 'DIVIDE' &&
                  num.tryParse(op.value.trim()) == 0) {
                return 'Math Op #$opIndex division by zero is not allowed.';
              }
            }
          }
        }
        if (current.compareTo == 'FIELD') {
          final pathErr = PolicyValidators.validateFieldPath(val?.toString());
          if (pathErr != null) {
            return 'Comparison target field path for "${fieldDef?.displayName ?? current.field}": $pathErr';
          }
        } else {
          if (val == null || val.toString().trim().isEmpty) {
            return 'Comparison target value is required for "${fieldDef?.displayName ?? current.field}".';
          }
        }
      } else if (vType == 'FIELD' || vType == 'FIELD_LIST') {
        final pathErr = PolicyValidators.validateFieldPath(val?.toString());
        if (pathErr != null) {
          return 'Field path for "${fieldDef?.displayName ?? current.field}": $pathErr';
        }
      } else {
        final isArrayOp =
            current.comparison == 'in' || current.comparison == 'not_in';
        if (isArrayOp) {
          final isNum = fieldDef?.fieldType == 'NUMBER';
          if (val is List) {
            if (val.isEmpty || val.every((e) => e.toString().trim().isEmpty)) {
              return 'At least one value is required for "${fieldDef?.displayName ?? current.field}".';
            }
            final isAge =
                (fieldDef?.fieldName.toLowerCase().contains('age') ?? false) ||
                (fieldDef?.displayName.toLowerCase().contains('age') ?? false);
            if (isNum) {
              for (final item in val) {
                if (isAge) {
                  final ageErr = PolicyValidators.validateAge(
                    item.toString().trim(),
                    fieldDef?.displayName ?? 'Patient Age',
                  );
                  if (ageErr != null) return ageErr;
                } else if (num.tryParse(item.toString().trim()) == null) {
                  return 'All values for "${fieldDef?.displayName ?? current.field}" must be valid numbers.';
                }
              }
            }
          } else {
            final isAge =
                (fieldDef?.fieldName.toLowerCase().contains('age') ?? false) ||
                (fieldDef?.displayName.toLowerCase().contains('age') ?? false);
            final arrErr = PolicyValidators.validateArrayValues(
              val?.toString(),
              isNumeric: isNum,
              isAge: isAge,
            );
            if (arrErr != null) {
              return 'Values for "${fieldDef?.displayName ?? current.field}": $arrErr';
            }
          }
        } else if (fieldDef?.fieldType == 'NUMBER') {
          final isAge =
              (fieldDef?.fieldName.toLowerCase().contains('age') ?? false) ||
              (fieldDef?.displayName.toLowerCase().contains('age') ?? false);
          if (isAge) {
            final ageErr = PolicyValidators.validateAge(
              val?.toString(),
              fieldDef?.displayName ?? 'Patient Age',
            );
            if (ageErr != null) return ageErr;
          } else {
            final numErr = PolicyValidators.validateNumber(
              val?.toString(),
              fieldDef?.displayName ?? 'Number',
            );
            if (numErr != null) return numErr;
          }
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
