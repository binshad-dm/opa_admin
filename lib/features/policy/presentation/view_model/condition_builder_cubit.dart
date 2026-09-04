import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/condition_tree_entity.dart';
import '../../domain/entities/field_definition_entity.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/usecases/get_fields_usecase.dart';
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

      String valStr = '';
      if (current.value is List) {
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

  bool get isValid {
    if (state.useCustomRego) {
      return state.customRegoSnippet.trim().isNotEmpty;
    }
    return !hasEmptyGroup();
  }
}
