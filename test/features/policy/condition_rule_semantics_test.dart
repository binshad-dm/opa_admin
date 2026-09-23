import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opa_admin/features/policy/domain/entities/condition_tree_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/field_definition_entity.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/condition_rule_widget.dart';

void main() {
  const sampleFields = [
    FieldDefinitionEntity(
      fieldName: 'department',
      displayName: 'Department',
      fieldType: 'STRING',
      allowedValues: ['Engineering', 'HR'],
    ),
    FieldDefinitionEntity(
      fieldName: 'active',
      displayName: 'Active',
      fieldType: 'BOOLEAN',
    ),
    FieldDefinitionEntity(
      fieldName: 'amount',
      displayName: 'Amount',
      fieldType: 'NUMBER',
    ),
  ];

  testWidgets(
    'ConditionRuleWidget renders Semantics for dropdowns and remove button',
    (tester) async {
      const rule = ConditionRuleEntity(
        field: 'department',
        comparison: '==',
        value: 'Engineering',
        valueType: 'VALUE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionRuleWidget(
              rule: rule,
              fields: sampleFields,
              permissionCode: 'test:permission',
              onChange: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Rule field'), findsOneWidget);
      expect(find.bySemanticsLabel('Rule comparison operator'), findsOneWidget);
      expect(find.bySemanticsLabel('Rule value type'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove rule'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Select value for Department'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ConditionRuleWidget renders Semantics for boolean and numeric inputs',
    (tester) async {
      const boolRule = ConditionRuleEntity(
        field: 'active',
        comparison: '==',
        value: true,
        valueType: 'VALUE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionRuleWidget(
              rule: boolRule,
              fields: sampleFields,
              permissionCode: 'test:permission',
              onChange: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Select boolean value for Active'),
        findsOneWidget,
      );

      const numRule = ConditionRuleEntity(
        field: 'amount',
        comparison: '<=',
        value: 100,
        valueType: 'VALUE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionRuleWidget(
              rule: numRule,
              fields: sampleFields,
              permissionCode: 'test:permission',
              onChange: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Numeric value for Amount'), findsOneWidget);
    },
  );

  testWidgets('ConditionRuleWidget renders Semantics for FIELD valueType', (
    tester,
  ) async {
    const fieldRule = ConditionRuleEntity(
      field: 'department',
      comparison: '==',
      value: 'user.department',
      valueType: 'FIELD',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConditionRuleWidget(
            rule: fieldRule,
            fields: sampleFields,
            permissionCode: 'test:permission',
            onChange: (_) {},
            onRemove: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Select field path suggestion'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Field path'), findsOneWidget);
  });
}
