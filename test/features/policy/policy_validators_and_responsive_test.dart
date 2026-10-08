import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opa_admin/features/policy/domain/entities/condition_tree_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/field_definition_entity.dart';
import 'package:opa_admin/features/policy/domain/utils/policy_validators.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/condition_rule_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/subject_selector_widget.dart';
import 'package:opa_admin/features/policy/presentation/view/widgets/policy_card_widget.dart';
import 'package:opa_admin/features/policy/domain/entities/policy_entity.dart';

void main() {
  group('PolicyValidators Unit Tests', () {
    test('validateRequired returns correct messages', () {
      expect(PolicyValidators.validateRequired(null, 'Value'), 'Value is required');
      expect(PolicyValidators.validateRequired('', 'Value'), 'Value is required');
      expect(PolicyValidators.validateRequired('   ', 'Name'), 'Name is required');
      expect(PolicyValidators.validateRequired('valid'), isNull);
    });

    test('validateFieldPath checks dot-notated identifier paths', () {
      expect(PolicyValidators.validateFieldPath(null), 'Field path is required');
      expect(PolicyValidators.validateFieldPath(''), 'Field path is required');
      expect(PolicyValidators.validateFieldPath('   '), 'Field path is required');

      // Invalid field paths
      expect(
        PolicyValidators.validateFieldPath('user..location'),
        'Enter a valid field path (e.g. user.department)',
      );
      expect(
        PolicyValidators.validateFieldPath('.user'),
        'Enter a valid field path (e.g. user.department)',
      );
      expect(
        PolicyValidators.validateFieldPath('user.location.'),
        'Enter a valid field path (e.g. user.department)',
      );
      expect(
        PolicyValidators.validateFieldPath('user location'),
        'Enter a valid field path (e.g. user.department)',
      );

      // Valid field paths
      expect(PolicyValidators.validateFieldPath('user.location'), isNull);
      expect(PolicyValidators.validateFieldPath('resource.allowedDepartments'), isNull);
      expect(PolicyValidators.validateFieldPath('claims.sub'), isNull);
      expect(PolicyValidators.validateFieldPath('singleIdentifier'), isNull);
    });

    test('validateArrayValues checks comma-separated items and numeric flags', () {
      expect(PolicyValidators.validateArrayValues(null), 'At least one value is required');
      expect(PolicyValidators.validateArrayValues(''), 'At least one value is required');
      expect(PolicyValidators.validateArrayValues('   ,  '), 'At least one non-empty value is required');

      // Valid string list
      expect(PolicyValidators.validateArrayValues('Engineering, HR, Product'), isNull);

      // Numeric list validation
      expect(
        PolicyValidators.validateArrayValues('10, 20, abc', isNumeric: true),
        'All values must be valid numbers (e.g. 10, 20)',
      );
      expect(
        PolicyValidators.validateArrayValues('10, 20.5, 30', isNumeric: true),
        isNull,
      );
    });

    test('validateNumber checks numeric validity', () {
      expect(PolicyValidators.validateNumber(null, 'Amount'), 'Amount value is required');
      expect(PolicyValidators.validateNumber('', 'Amount'), 'Amount value is required');
      expect(PolicyValidators.validateNumber('abc', 'Amount'), 'Enter a valid number');
      expect(PolicyValidators.validateNumber('123', 'Amount'), isNull);
      expect(PolicyValidators.validateNumber('-45.67', 'Amount'), isNull);
    });

    test('validateRegoSnippet validates non-emptiness and bracket/quote balance', () {
      expect(PolicyValidators.validateRegoSnippet(null), 'Rego code snippet is required');
      expect(PolicyValidators.validateRegoSnippet(''), 'Rego code snippet is required');
      expect(PolicyValidators.validateRegoSnippet('   '), 'Rego code snippet is required');

      // Valid rego snippets
      expect(
        PolicyValidators.validateRegoSnippet('allow {\n  input.user.role == "ADMIN"\n}'),
        isNull,
      );
      expect(
        PolicyValidators.validateRegoSnippet('# comment\nallow = true'),
        isNull,
      );

      // Unmatched brackets
      expect(
        PolicyValidators.validateRegoSnippet('allow {\n  input.user.role == "ADMIN"'),
        contains('Unclosed bracket "{"'),
      );
      expect(
        PolicyValidators.validateRegoSnippet('allow {\n  input.roles[0 == "ADMIN"\n}'),
        contains('Mismatched brackets'),
      );
      expect(
        PolicyValidators.validateRegoSnippet('allow }'),
        contains('Unexpected closing bracket "}"'),
      );

      // Unterminated quotes
      expect(
        PolicyValidators.validateRegoSnippet('allow {\n  input.user.role == "ADMIN\n}'),
        contains('Unterminated string literal'),
      );
    });

    test('isNumericField and isBooleanField correctly identify field types', () {
      const numField = FieldDefinitionEntity(
        fieldName: 'patientAge',
        displayName: 'Patient Age',
        fieldType: 'NUMBER',
      );
      const strField = FieldDefinitionEntity(
        fieldName: 'doctorSpecialty',
        displayName: 'Doctor Specialty',
        fieldType: 'STRING',
      );
      const boolField = FieldDefinitionEntity(
        fieldName: 'isEmergency',
        displayName: 'Is Emergency',
        fieldType: 'BOOLEAN',
      );

      expect(PolicyValidators.isNumericField(numField), isTrue);
      expect(PolicyValidators.isNumericField(null, 'patientAge'), isTrue);
      expect(PolicyValidators.isNumericField(strField), isFalse);
      expect(PolicyValidators.isBooleanField(boolField), isTrue);
      expect(PolicyValidators.isBooleanField(numField), isFalse);
      expect(PolicyValidators.isBooleanField(strField), isFalse);
    });

    test('getAllowedOperators filters operators based on field type', () {
      const numField = FieldDefinitionEntity(
        fieldName: 'patientAge',
        displayName: 'Patient Age',
        fieldType: 'NUMBER',
      );
      const strField = FieldDefinitionEntity(
        fieldName: 'doctorSpecialty',
        displayName: 'Doctor Specialty',
        fieldType: 'STRING',
      );
      const boolField = FieldDefinitionEntity(
        fieldName: 'isEmergency',
        displayName: 'Is Emergency',
        fieldType: 'BOOLEAN',
      );

      final numOps = PolicyValidators.getAllowedOperators(numField);
      expect(numOps, contains('=='));
      expect(numOps, contains('<='));
      expect(numOps, contains('>'));
      expect(numOps, contains('in'));
      // Bug 1: contains must NOT be allowed for numeric fields!
      expect(numOps, isNot(contains('contains')));

      final strOps = PolicyValidators.getAllowedOperators(strField);
      expect(strOps, contains('=='));
      expect(strOps, contains('contains'));
      expect(strOps, contains('in'));
      // Bug 2 & 3: numeric comparisons must NOT be allowed for string fields!
      expect(strOps, isNot(contains('>')));
      expect(strOps, isNot(contains('<')));
      expect(strOps, isNot(contains('>=')));
      expect(strOps, isNot(contains('<=')));

      final boolOps = PolicyValidators.getAllowedOperators(boolField);
      expect(boolOps, equals(['==', '!=']));
    });

    test('getAllowedValueTypes only includes MATH_EXPRESSION for numeric fields', () {
      const numField = FieldDefinitionEntity(
        fieldName: 'patientAge',
        displayName: 'Patient Age',
        fieldType: 'NUMBER',
      );
      const strField = FieldDefinitionEntity(
        fieldName: 'doctorSpecialty',
        displayName: 'Doctor Specialty',
        fieldType: 'STRING',
      );

      final numTypes = PolicyValidators.getAllowedValueTypes(numField).map((e) => e.key).toList();
      expect(numTypes, contains('MATH_EXPRESSION'));

      final strTypes = PolicyValidators.getAllowedValueTypes(strField).map((e) => e.key).toList();
      expect(strTypes, isNot(contains('MATH_EXPRESSION')));
    });

    test('validateRuleOperator and validateRuleValueType flag invalid combinations', () {
      const numField = FieldDefinitionEntity(
        fieldName: 'patientAge',
        displayName: 'Patient Age',
        fieldType: 'NUMBER',
      );
      const strField = FieldDefinitionEntity(
        fieldName: 'doctorSpecialty',
        displayName: 'Doctor Specialty',
        fieldType: 'STRING',
      );

      // Bug 1: contains on Patient Age
      expect(
        PolicyValidators.validateRuleOperator('contains', numField),
        contains('not supported for numeric field "Patient Age"'),
      );

      // Bug 2 & 3: > on Doctor Specialty
      expect(
        PolicyValidators.validateRuleOperator('>', strField),
        contains('not supported for string field "Doctor Specialty"'),
      );

      // Math expression on string field
      expect(
        PolicyValidators.validateRuleValueType('MATH_EXPRESSION', strField),
        contains('Math expression is only supported for numeric fields'),
      );

      // Valid combinations
      expect(PolicyValidators.validateRuleOperator('<=', numField), isNull);
      expect(PolicyValidators.validateRuleOperator('contains', strField), isNull);
      expect(PolicyValidators.validateRuleValueType('VALUE', strField), isNull);
      expect(PolicyValidators.validateRuleValueType('MATH_EXPRESSION', numField), isNull);
    });
  });

  group('Responsive Widget Layout Tests', () {
    const sampleFields = [
      FieldDefinitionEntity(
        fieldName: 'department',
        displayName: 'Department',
        fieldType: 'STRING',
        allowedValues: ['Engineering', 'HR'],
      ),
      FieldDefinitionEntity(
        fieldName: 'amount',
        displayName: 'Amount',
        fieldType: 'NUMBER',
      ),
    ];

    testWidgets('ConditionRuleWidget adapts to mobile width (< 460px) without overflow', (
      tester,
    ) async {
      // Simulate mobile screen: 360 x 640
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const rule = ConditionRuleEntity(
        field: 'amount',
        comparison: '>=',
        value: 100,
        valueType: 'VALUE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              child: ConditionRuleWidget(
                rule: rule,
                fields: sampleFields,
                permissionCode: 'test:perm',
                onChange: (_) {},
                onRemove: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Numeric value for Amount'), findsOneWidget);
    });

    testWidgets('SubjectSelectorWidget stacks on mobile (< 480px) and rows on web', (
      tester,
    ) async {
      // Mobile width 360px
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              child: SubjectSelectorWidget(
                subjectType: 'ROLE',
                subjectId: 'admin',
                roles: const [],
                users: const [],
                onSubjectTypeChanged: (_) {},
                onSubjectIdChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Subject Type'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
    });

    testWidgets('PolicyCardWidget does not overflow horizontally with long reason on mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const longPolicy = PolicyEntity(
        permissionCode: 'appointments:delete',
        resourceName: 'appointments',
        action: 'delete',
        enabled: false,
        disabledReason: 'Disabled by administrator due to organizational safety policies',
        useCustomRego: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: PolicyCardWidget(
                policy: longPolicy,
                onToggle: (_) {},
                onEditConditions: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('DELETE'), findsOneWidget);
      expect(find.textContaining('Disabled by administrator'), findsOneWidget);
    });
  });
}
