import 'package:flutter_test/flutter_test.dart';
import 'package:opa_admin/features/policy/data/models/role_dto_model.dart';
import 'package:opa_admin/features/policy/data/models/user_dto_model.dart';
import 'package:opa_admin/features/policy/domain/entities/condition_tree_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/field_definition_entity.dart';
import 'package:opa_admin/features/policy/presentation/view_model/condition_builder_cubit.dart';
import 'package:opa_admin/features/policy/domain/usecases/get_fields_usecase.dart';
import 'package:dartz/dartz.dart';

import 'package:opa_admin/core/error/failure.dart';

class MockGetFieldsUseCase implements GetFieldsUseCase {
  final List<FieldDefinitionEntity> fields;
  MockGetFieldsUseCase(this.fields);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, List<FieldDefinitionEntity>>> call(String params) async {
    return Right(fields);
  }
}

void main() {
  group('ConditionTreeEntity Tests', () {
    test('ConditionRuleEntity default valueType is VALUE', () {
      const rule = ConditionRuleEntity(
        field: 'quantity',
        comparison: '<=',
        value: 100,
      );
      expect(rule.valueType, 'VALUE');
      expect(rule.toJson(), {
        'field': 'quantity',
        'comparison': '<=',
        'value': 100,
        'valueType': 'VALUE',
      });
    });

    test('ConditionRuleEntity serialization with FIELD and FIELD_LIST', () {
      const fieldRule = ConditionRuleEntity(
        field: 'assignedLocation',
        comparison: '==',
        value: 'user.location',
        valueType: 'FIELD',
      );
      expect(fieldRule.toJson(), {
        'field': 'assignedLocation',
        'comparison': '==',
        'value': 'user.location',
        'valueType': 'FIELD',
      });

      const fieldListRule = ConditionRuleEntity(
        field: 'user.department',
        comparison: 'in',
        value: 'resource.allowedDepartments',
        valueType: 'FIELD_LIST',
      );
      expect(fieldListRule.toJson(), {
        'field': 'user.department',
        'comparison': 'in',
        'value': 'resource.allowedDepartments',
        'valueType': 'FIELD_LIST',
      });
    });

    test('ConditionNodeEntity fromJson parses valueType correctly', () {
      final json = {
        'operator': 'AND',
        'children': [
          {
            'field': 'quantity',
            'comparison': '<=',
            'value': 100,
            'valueType': 'VALUE',
          },
          {
            'field': 'assignedLocation',
            'comparison': '==',
            'value': 'user.location',
            'valueType': 'FIELD',
          },
          {
            'field': 'user.department',
            'comparison': 'in',
            'value': 'resource.allowedDepartments',
            'valueType': 'FIELD_LIST',
          },
        ],
      };

      final node = ConditionNodeEntity.fromJson(json);
      expect(node, isA<ConditionGroupEntity>());
      final group = node as ConditionGroupEntity;
      expect(group.children.length, 3);

      final r1 = group.children[0] as ConditionRuleEntity;
      expect(r1.field, 'quantity');
      expect(r1.valueType, 'VALUE');

      final r2 = group.children[1] as ConditionRuleEntity;
      expect(r2.field, 'assignedLocation');
      expect(r2.value, 'user.location');
      expect(r2.valueType, 'FIELD');

      final r3 = group.children[2] as ConditionRuleEntity;
      expect(r3.field, 'user.department');
      expect(r3.value, 'resource.allowedDepartments');
      expect(r3.valueType, 'FIELD_LIST');
    });

    test('ConditionNodeEntity fromJson defaults valueType to VALUE if missing', () {
      final json = {
        'field': 'status',
        'comparison': '==',
        'value': 'ACTIVE',
      };
      final node = ConditionNodeEntity.fromJson(json);
      expect(node, isA<ConditionRuleEntity>());
      final rule = node as ConditionRuleEntity;
      expect(rule.valueType, 'VALUE');
    });
  });

  group('ConditionBuilder Preview Tests', () {
    test('generatePreview formats VALUE, FIELD, and FIELD_LIST correctly', () {
      final fields = [
        const FieldDefinitionEntity(
          fieldName: 'quantity',
          displayName: 'Quantity',
          fieldType: 'NUMBER',
        ),
        const FieldDefinitionEntity(
          fieldName: 'assignedLocation',
          displayName: 'Assigned Location',
          fieldType: 'STRING',
        ),
        const FieldDefinitionEntity(
          fieldName: 'user.department',
          displayName: 'User Department',
          fieldType: 'STRING',
        ),
      ];

      final cubit = ConditionBuilderCubit(
        getFieldsUseCase: MockGetFieldsUseCase(fields),
      );

      final tree = ConditionGroupEntity(
        operator: 'AND',
        children: const [
          ConditionRuleEntity(
            field: 'quantity',
            comparison: '<=',
            value: 100,
            valueType: 'VALUE',
          ),
          ConditionRuleEntity(
            field: 'assignedLocation',
            comparison: '==',
            value: 'user.location',
            valueType: 'FIELD',
          ),
          ConditionRuleEntity(
            field: 'user.department',
            comparison: 'in',
            value: 'resource.allowedDepartments',
            valueType: 'FIELD_LIST',
          ),
        ],
      );

      cubit.emit(cubit.state.copyWith(
        fields: fields,
        expressionTree: tree,
      ));

      final preview = cubit.generatePreview();
      expect(preview, contains('Quantity <= 100'));
      expect(preview, contains('Assigned Location == user.location (Field)'));
      expect(preview, contains('User Department in resource.allowedDepartments (Field List)'));
      expect(preview, contains('AND'));
    });

    test('validationError detects empty group', () {
      final cubit = ConditionBuilderCubit(
        getFieldsUseCase: MockGetFieldsUseCase(const []),
      );

      cubit.emit(cubit.state.copyWith(
        expressionTree: const ConditionGroupEntity(operator: 'AND', children: []),
      ));

      expect(cubit.validationError, contains('Empty group detected'));
      expect(cubit.isValid, isFalse);
    });

    test('validationError detects invalid field path and validates correct rules', () {
      final fields = [
        const FieldDefinitionEntity(
          fieldName: 'assignedLocation',
          displayName: 'Assigned Location',
          fieldType: 'STRING',
        ),
      ];

      final cubit = ConditionBuilderCubit(
        getFieldsUseCase: MockGetFieldsUseCase(fields),
      );

      // Invalid field path with double dot
      cubit.emit(cubit.state.copyWith(
        fields: fields,
        expressionTree: const ConditionGroupEntity(
          operator: 'AND',
          children: [
            ConditionRuleEntity(
              field: 'assignedLocation',
              comparison: '==',
              value: 'user..location',
              valueType: 'FIELD',
            ),
          ],
        ),
      ));

      expect(cubit.validationError, contains('Enter a valid field path'));
      expect(cubit.isValid, isFalse);

      // Valid field path
      cubit.emit(cubit.state.copyWith(
        fields: fields,
        expressionTree: const ConditionGroupEntity(
          operator: 'AND',
          children: [
            ConditionRuleEntity(
              field: 'assignedLocation',
              comparison: '==',
              value: 'user.location',
              valueType: 'FIELD',
            ),
          ],
        ),
      ));

      expect(cubit.validationError, isNull);
      expect(cubit.isValid, isTrue);
    });

    test('validationError validates custom rego snippets', () {
      final cubit = ConditionBuilderCubit(
        getFieldsUseCase: MockGetFieldsUseCase(const []),
      );

      // Empty custom rego
      cubit.emit(cubit.state.copyWith(
        useCustomRego: true,
        customRegoSnippet: '   ',
      ));
      expect(cubit.validationError, contains('Rego code snippet is required'));
      expect(cubit.isValid, isFalse);

      // Rego with unclosed bracket
      cubit.emit(cubit.state.copyWith(
        useCustomRego: true,
        customRegoSnippet: 'allow {\n  input.user.role == "ADMIN"',
      ));
      expect(cubit.validationError, contains('Unclosed bracket "{"'));
      expect(cubit.isValid, isFalse);

      // Valid rego
      cubit.emit(cubit.state.copyWith(
        useCustomRego: true,
        customRegoSnippet: 'allow {\n  input.user.role == "ADMIN"\n}',
      ));
      expect(cubit.validationError, isNull);
      expect(cubit.isValid, isTrue);
    });
  });

  group('Subject Model Fallback Tests', () {
    test('RoleDtoModel parses Identity Service format', () {
      final json = {
        'id': 'role-uuid-1',
        'name': 'PHARMACIST',
        'description': 'Pharmacy Role',
      };
      final role = RoleDtoModel.fromJson(json);
      expect(role.id, 'role-uuid-1');
      expect(role.name, 'PHARMACIST');
    });

    test('RoleDtoModel parses projected subject fallback format', () {
      final json = {
        'subjectId': 'role-uuid-2',
        'subjectName': 'PHARMACIST',
        'displayName': 'Pharmacist Role',
      };
      final role = RoleDtoModel.fromJson(json);
      expect(role.id, 'role-uuid-2');
      expect(role.name, 'PHARMACIST');
    });

    test('UserDtoModel parses Identity Service format', () {
      final json = {
        'id': '101',
        'email': 'john.doe@hospital.org',
        'firstName': 'John',
        'lastName': 'Doe',
      };
      final user = UserDtoModel.fromJson(json);
      expect(user.id, '101');
      expect(user.email, 'john.doe@hospital.org');
      expect(user.displayName, 'John Doe (john.doe@hospital.org)');
    });

    test('UserDtoModel parses projected subject fallback format', () {
      final json = {
        'subjectId': '102',
        'subjectName': 'jane.doe@hospital.org',
        'displayName': 'Jane Doe',
      };
      final user = UserDtoModel.fromJson(json);
      expect(user.id, '102');
      expect(user.email, 'jane.doe@hospital.org');
    });
  });
}
