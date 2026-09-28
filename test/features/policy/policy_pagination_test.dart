import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opa_admin/core/error/failure.dart';
import 'package:opa_admin/features/policy/data/models/policy_model.dart';
import 'package:opa_admin/features/policy/domain/entities/field_definition_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/policy_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/role_dto_entity.dart';
import 'package:opa_admin/features/policy/domain/entities/user_dto_entity.dart';
import 'package:opa_admin/features/policy/domain/repositories/policy_repository.dart';
import 'package:opa_admin/features/policy/domain/usecases/get_namespaces_usecase.dart';
import 'package:opa_admin/features/policy/domain/usecases/get_policies_usecase.dart';
import 'package:opa_admin/features/policy/domain/usecases/get_roles_usecase.dart';
import 'package:opa_admin/features/policy/domain/usecases/get_users_usecase.dart';
import 'package:opa_admin/features/policy/domain/usecases/save_policies_usecase.dart';
import 'package:opa_admin/features/policy/presentation/view_model/policy_cubit.dart';
import 'package:opa_admin/features/policy/presentation/view_model/policy_state.dart';
import 'package:opa_admin/shared/component/pagination_component.dart';

class MockPolicyRepository implements PolicyRepository {
  int lastRequestedPage = 1;
  int lastRequestedSize = 10;
  String? lastRequestedSearch;
  List<PolicyEntity> savedPolicies = [];

  final List<PolicyEntity> allPolicies = List.generate(
    25,
    (index) => PolicyEntity(
      permissionCode: 'pharmacy:item_$index:read',
      resourceName: 'item_$index',
      action: 'read',
      namespace: 'pharmacy',
      enabled: false,
    ),
  );

  @override
  Future<Either<Failure, PaginatedData<PolicyEntity>>> getPolicies({
    required String subjectType,
    required String subjectId,
    required String namespace,
    int page = 1,
    int size = 10,
    String? search,
  }) async {
    lastRequestedPage = page;
    lastRequestedSize = size;
    lastRequestedSearch = search;

    var filtered = allPolicies;
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((p) => p.permissionCode.contains(search) || p.resourceName.contains(search))
          .toList();
    }

    final start = (page - 1) * size;
    final end = (start + size).clamp(0, filtered.length);
    final items = (start < filtered.length) ? filtered.sublist(start, end) : <PolicyEntity>[];
    final totalPages = (filtered.length / size).ceil();

    return Right(
      PaginatedData<PolicyEntity>(
        items: items,
        totalItems: filtered.length,
        currentPage: page,
        totalPages: totalPages > 0 ? totalPages : 1,
        itemsPerPage: size,
      ),
    );
  }

  @override
  Future<Either<Failure, String>> savePolicies({
    required String subjectType,
    required String subjectId,
    required String namespace,
    required List<PolicyEntity> policies,
  }) async {
    savedPolicies = policies;
    return const Right('Saved successfully');
  }

  @override
  Future<Either<Failure, List<FieldDefinitionEntity>>> getFields({required String permissionCode}) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<RoleDtoEntity>>> getRoles() async {
    return const Right([RoleDtoEntity(id: 'ADMIN', name: 'Admin')]);
  }

  @override
  Future<Either<Failure, List<UserDtoEntity>>> getUsers() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<String>>> getNamespaces() async {
    return const Right(['pharmacy', 'finance']);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDynamicOptions({
    required String permissionCode,
    required String endpoint,
    required int page,
    required String search,
  }) async {
    return const Right({});
  }
}

void main() {
  group('PolicyModel Pagination & New Schema Unit Tests', () {
    test('PolicyModel correctly parses new data model from backend', () {
      final sampleJson = {
        "permissionCode": "pharmacy:medication:dispense",
        "action": "dispense",
        "namespace": "pharmacy",
        "resourceName": "medication",
        "policyId": null,
        "effect": null,
        "expressionJson": null,
        "enabled": false,
        "disabledReason": null,
        "deletedReason": null,
        "deprecated": false,
        "useCustomRego": false,
        "customRegoSnippet": null,
      };

      final model = PolicyModel.fromJson(sampleJson);

      expect(model.permissionCode, 'pharmacy:medication:dispense');
      expect(model.action, 'dispense');
      expect(model.namespace, 'pharmacy');
      expect(model.resourceName, 'medication');
      expect(model.policyId, isNull);
      expect(model.effect, 'ALLOW');
      expect(model.expressionJson, isNull);
      expect(model.enabled, isFalse);
      expect(model.disabledReason, isNull);
      expect(model.deletedReason, isNull);
      expect(model.deprecated, isFalse);
      expect(model.useCustomRego, isFalse);
      expect(model.customRegoSnippet, isNull);
    });

    test('PolicyModel handles non-null policyId, stringified expressionJson, and deprecated flag', () {
      final sampleJson = {
        "permissionCode": "pharmacy:prescription:create",
        "action": "create",
        "namespace": "pharmacy",
        "resourceName": "prescription",
        "policyId": 42,
        "effect": "ALLOW",
        "expressionJson": '{"rule": "active"}',
        "enabled": true,
        "disabledReason": null,
        "deletedReason": null,
        "deprecated": true,
        "useCustomRego": false,
        "customRegoSnippet": null,
      };

      final model = PolicyModel.fromJson(sampleJson);

      expect(model.permissionCode, 'pharmacy:prescription:create');
      expect(model.policyId, '42');
      expect(model.deprecated, isTrue);
      expect(model.enabled, isTrue);
      expect(model.expressionJson, isNotNull);
      expect(model.expressionJson!['rule'], 'active');

      final serialized = model.toJson();
      expect(serialized['permissionCode'], 'pharmacy:prescription:create');
      expect(serialized['policyId'], '42');
      expect(serialized['deprecated'], isTrue);
      expect(serialized['enabled'], isTrue);
    });

    test('PaginatedData can wrap parsed content and computes correctly', () {
      final backendResponse = {
        "content": [
          {
            "permissionCode": "pharmacy:medication:dispense",
            "action": "dispense",
            "namespace": "pharmacy",
            "resourceName": "medication",
            "policyId": null,
            "effect": null,
            "expressionJson": null,
            "enabled": false,
            "disabledReason": null,
            "deletedReason": null,
            "deprecated": false,
            "useCustomRego": false,
            "customRegoSnippet": null,
          },
          {
            "permissionCode": "pharmacy:prescription:create",
            "action": "create",
            "namespace": "pharmacy",
            "resourceName": "prescription",
            "policyId": null,
            "effect": null,
            "expressionJson": null,
            "enabled": false,
            "disabledReason": null,
            "deletedReason": null,
            "deprecated": false,
            "useCustomRego": false,
            "customRegoSnippet": null,
          },
        ],
        "pageNumber": 1,
        "pageSize": 10,
        "totalElements": 2,
        "totalPages": 1,
        "hasNext": false,
        "hasPrevious": false,
      };

      final content = (backendResponse['content'] as List)
          .map((e) => PolicyModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final paginatedData = PaginatedData<PolicyModel>(
        items: content,
        totalItems: backendResponse['totalElements'] as int,
        currentPage: backendResponse['pageNumber'] as int,
        totalPages: backendResponse['totalPages'] as int,
        itemsPerPage: backendResponse['pageSize'] as int,
      );

      expect(paginatedData.items.length, 2);
      expect(paginatedData.totalItems, 2);
      expect(paginatedData.currentPage, 1);
      expect(paginatedData.totalPages, 1);
      expect(paginatedData.itemsPerPage, 10);
    });
  });

  group('PolicyCubit Pagination & Search Tests', () {
    late MockPolicyRepository repository;
    late PolicyCubit cubit;

    setUp(() {
      repository = MockPolicyRepository();
      cubit = PolicyCubit(
        getPoliciesUseCase: GetPoliciesUseCase(repository),
        savePoliciesUseCase: SavePoliciesUseCase(repository),
        getRolesUseCase: GetRolesUseCase(repository),
        getUsersUseCase: GetUsersUseCase(repository),
        getNamespacesUseCase: GetNamespacesUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initDashboard initializes with first page and paginated state', () async {
      await cubit.initDashboard();

      expect(cubit.state, isA<PolicyLoaded>());
      final loaded = cubit.state as PolicyLoaded;
      expect(loaded.paginatedPolicies.currentPage, 1);
      expect(loaded.paginatedPolicies.itemsPerPage, 10);
      expect(loaded.paginatedPolicies.totalItems, 25);
      expect(loaded.paginatedPolicies.totalPages, 3);
      expect(loaded.paginatedPolicies.items.length, 10);
    });

    test('changePage loads requested page number', () async {
      await cubit.initDashboard();
      cubit.changePage(2);
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as PolicyLoaded;
      expect(loaded.paginatedPolicies.currentPage, 2);
      expect(loaded.paginatedPolicies.items.first.permissionCode, 'pharmacy:item_10:read');
    });

    test('changePageSize resets to page 1 with new itemsPerPage', () async {
      await cubit.initDashboard();
      cubit.changePage(2);
      await Future.delayed(const Duration(milliseconds: 50));

      cubit.changePageSize(5);
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as PolicyLoaded;
      expect(loaded.paginatedPolicies.currentPage, 1);
      expect(loaded.paginatedPolicies.itemsPerPage, 5);
      expect(loaded.paginatedPolicies.items.length, 5);
    });

    test('togglePolicy preserves toggled state in modifiedPolicies across pages', () async {
      await cubit.initDashboard();

      // Toggle first item on page 1
      final targetCode = 'pharmacy:item_0:read';
      cubit.togglePolicy(targetCode);

      var loaded = cubit.state as PolicyLoaded;
      expect(loaded.paginatedPolicies.items.first.enabled, isTrue);
      expect(loaded.modifiedPolicies[targetCode]?.enabled, isTrue);

      // Navigate to page 2
      cubit.changePage(2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Navigate back to page 1
      cubit.changePage(1);
      await Future.delayed(const Duration(milliseconds: 50));

      loaded = cubit.state as PolicyLoaded;
      // Item 0 should STILL be enabled because modifiedPolicies was merged!
      expect(loaded.paginatedPolicies.items.first.enabled, isTrue);
    });

    test('savePolicies saves modified policies from memory', () async {
      await cubit.initDashboard();

      cubit.togglePolicy('pharmacy:item_0:read');
      final message = await cubit.savePolicies();

      expect(message, 'Saved successfully');
      expect(repository.savedPolicies.any((p) => p.permissionCode == 'pharmacy:item_0:read'), isTrue);
    });
  });
}
