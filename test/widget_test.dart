import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opa_admin/features/policy/domain/entities/condition_tree_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/field_definition_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/policy_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/role_dto_entity.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/condition_group_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/condition_rule_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/custom_rego_editor_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/policy_card_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/policy_grid_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/subject_selector_widget.dart';

void main() {
  testWidgets('PolicyCardWidget exposes semantics labels and identifiers', (
    WidgetTester tester,
  ) async {
    const policy = PolicyEntity(
      permissionCode: 'PERM_PATIENT_READ',
      resourceName: 'patient',
      action: 'read',
      enabled: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PolicyCardWidget(
            policy: policy,
            onToggle: (_) {},
            onEditConditions: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'policy_switch_PERM_PATIENT_READ' &&
            w.properties.toggled == true,
      ),
      findsOneWidget,
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier ==
                'configure_conditions_button_PERM_PATIENT_READ',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SubjectSelectorWidget renders with semantics identifiers', (
    WidgetTester tester,
  ) async {
    final roles = [
      const RoleDtoEntity(id: 'role-1', name: 'Admin', description: ''),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubjectSelectorWidget(
            subjectType: 'ROLE',
            subjectId: 'role-1',
            roles: roles,
            users: const [],
            onSubjectTypeChanged: (_) {},
            onSubjectIdChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'subject_type_dropdown',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.identifier == 'subject_id_dropdown',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PolicyGridWidget renders with group headers and empty semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PolicyGridWidget(
            policies: [],
            onTogglePolicy: _dummyToggle,
            onEditConditions: _dummyEdit,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'No policies found for this module and subject',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ConditionGroupWidget and ConditionRuleWidget semantics', (
    WidgetTester tester,
  ) async {
    const fields = [
      FieldDefinitionEntity(
        fieldName: 'status',
        displayName: 'Status',
        fieldType: 'STRING',
      ),
    ];

    const group = ConditionGroupEntity(
      operator: 'AND',
      children: [
        ConditionRuleEntity(field: 'status', comparison: '==', value: 'ACTIVE'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConditionGroupWidget(
            node: group,
            fields: fields,
            permissionCode: 'PERM_PATIENT_READ',
            onChange: (_) {},
            isRoot: true,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'condition_group_operator_dropdown',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.identifier == 'add_rule_button',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.identifier == 'rule_field_dropdown',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'rule_comparison_dropdown',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'rule_value_text_input',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.identifier == 'remove_rule_button',
      ),
      findsOneWidget,
    );
  });

  testWidgets('CustomRegoEditorWidget exposes code editor semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomRegoEditorWidget(
            snippet: 'allow = true',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'custom_rego_editor_field',
      ),
      findsOneWidget,
    );
  });
}

void _dummyToggle(String s) {}
void _dummyEdit(String s) {}
