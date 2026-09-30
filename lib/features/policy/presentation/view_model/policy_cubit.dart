import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/component/pagination_component.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/entities/role_dto_entity.dart';
import '../../domain/entities/user_dto_entity.dart';
import '../../domain/usecases/get_namespaces_usecase.dart';
import '../../domain/usecases/get_policies_usecase.dart';
import '../../domain/usecases/get_roles_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/save_policies_usecase.dart';
import 'policy_state.dart';

class PolicyCubit extends Cubit<PolicyState> {
  final GetPoliciesUseCase getPoliciesUseCase;
  final SavePoliciesUseCase savePoliciesUseCase;
  final GetRolesUseCase getRolesUseCase;
  final GetUsersUseCase getUsersUseCase;
  final GetNamespacesUseCase getNamespacesUseCase;

  Timer? _debounceTimer;

  PolicyCubit({
    required this.getPoliciesUseCase,
    required this.savePoliciesUseCase,
    required this.getRolesUseCase,
    required this.getUsersUseCase,
    required this.getNamespacesUseCase,
  }) : super(PolicyInitial());

  Future<void> initDashboard() async {
    emit(const PolicyLoading(message: 'Loading authorization dashboard...'));

    final rolesRes = await getRolesUseCase();
    final usersRes = await getUsersUseCase();
    final namespacesRes = await getNamespacesUseCase();

    List<RoleDtoEntity> roles = [];
    List<UserDtoEntity> users = [];
    List<String> modules = ['finance', 'clinical', 'pharmacy'];

    rolesRes.fold((_) {}, (r) => roles = r);
    usersRes.fold((_) {}, (u) => users = u);
    namespacesRes.fold((_) {}, (m) {
      if (m.isNotEmpty) modules = m;
    });

    String subjectType = 'ROLE';
    String subjectId = '';
    final activeRoles = roles
        .where((r) =>
            r.status.isEmpty ||
            r.status == 'null' ||
            r.status.toLowerCase() == 'active')
        .toList();
    if (activeRoles.isNotEmpty) {
      subjectId = activeRoles.first.id;
    } else if (roles.isNotEmpty) {
      subjectId = roles.first.id;
    }

    String moduleName = modules.isNotEmpty ? modules.first : 'finance';

    if (subjectId.isEmpty && users.isNotEmpty) {
      final activeUsers = users
          .where((u) =>
              u.status.isEmpty ||
              u.status == 'null' ||
              u.status.toLowerCase() == 'active')
          .toList();
      subjectType = 'USER';
      subjectId =
          activeUsers.isNotEmpty ? activeUsers.first.id : users.first.id;
    }

    if (subjectId.isNotEmpty) {
      final policiesRes = await getPoliciesUseCase(
        subjectType: subjectType,
        subjectId: subjectId,
        namespace: moduleName,
        page: 1,
        size: 10,
        search: '',
      );

      PaginatedData<PolicyEntity> paginated = const PaginatedData<PolicyEntity>(
        items: [],
        totalItems: 0,
        currentPage: 1,
        totalPages: 1,
        itemsPerPage: 10,
      );
      policiesRes.fold((_) {}, (p) => paginated = p);

      emit(
        PolicyLoaded(
          subjectType: subjectType,
          subjectId: subjectId,
          selectedModule: moduleName,
          availableModules: modules,
          roles: roles,
          users: users,
          paginatedPolicies: paginated,
          searchQuery: '',
          modifiedPolicies: const {},
        ),
      );
    } else {
      emit(
        PolicyLoaded(
          subjectType: subjectType,
          subjectId: subjectId,
          selectedModule: moduleName,
          availableModules: modules,
          roles: roles,
          users: users,
          paginatedPolicies: const PaginatedData<PolicyEntity>(
            items: [],
            totalItems: 0,
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: 10,
          ),
          searchQuery: '',
          modifiedPolicies: const {},
        ),
      );
    }
  }

  Future<void> loadPolicies({int? page, int? size, String? search}) async {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    if (currentState.subjectId.isEmpty) {
      emit(
        currentState.copyWith(
          paginatedPolicies: PaginatedData<PolicyEntity>(
            items: const [],
            totalItems: 0,
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: size ?? currentState.paginatedPolicies.itemsPerPage,
          ),
          searchQuery: search ?? currentState.searchQuery,
        ),
      );
      return;
    }

    final targetPage = page ?? currentState.paginatedPolicies.currentPage;
    final targetSize = size ?? currentState.paginatedPolicies.itemsPerPage;
    final targetSearch = search ?? currentState.searchQuery;

    emit(currentState.copyWith(isSaving: false));

    final result = await getPoliciesUseCase(
      subjectType: currentState.subjectType,
      subjectId: currentState.subjectId,
      namespace: currentState.selectedModule,
      page: targetPage,
      size: targetSize,
      search: targetSearch,
    );

    result.fold((failure) => emit(PolicyError(failure.message)), (paginated) {
      // Merge any user modifications that were made to policies on this page
      final mergedItems = paginated.items.map((p) {
        if (currentState.modifiedPolicies.containsKey(p.permissionCode)) {
          return currentState.modifiedPolicies[p.permissionCode]!;
        }
        return p;
      }).toList();

      final updatedPaginated = paginated.copyWith(items: mergedItems);

      emit(
        currentState.copyWith(
          paginatedPolicies: updatedPaginated,
          searchQuery: targetSearch,
        ),
      );
    });
  }

  void changePage(int newPage) {
    if (state is! PolicyLoaded) return;
    loadPolicies(page: newPage);
  }

  void changePageSize(int newSize) {
    if (state is! PolicyLoaded) return;
    loadPolicies(page: 1, size: newSize);
  }

  void searchPolicies(String query) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    emit(currentState.copyWith(searchQuery: query));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadPolicies(page: 1, search: query);
    });
  }

  void setSubjectType(String newType) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    String newSubjectId = '';
    if (newType == 'ROLE') {
      final activeRoles = currentState.roles
          .where((r) =>
              r.status.isEmpty ||
              r.status == 'null' ||
              r.status.toLowerCase() == 'active')
          .toList();
      if (activeRoles.isNotEmpty) {
        newSubjectId = activeRoles.first.id;
      } else if (currentState.roles.isNotEmpty) {
        newSubjectId = currentState.roles.first.id;
      }
    } else if (newType == 'USER') {
      final activeUsers = currentState.users
          .where((u) =>
              u.status.isEmpty ||
              u.status == 'null' ||
              u.status.toLowerCase() == 'active')
          .toList();
      if (activeUsers.isNotEmpty) {
        newSubjectId = activeUsers.first.id;
      } else if (currentState.users.isNotEmpty) {
        newSubjectId = currentState.users.first.id;
      }
    }

    emit(
      currentState.copyWith(
        subjectType: newType,
        subjectId: newSubjectId,
        modifiedPolicies: const {},
        searchQuery: '',
      ),
    );

    loadPolicies(page: 1, search: '');
  }

  void setSubjectId(String id) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    emit(
      currentState.copyWith(
        subjectId: id,
        modifiedPolicies: const {},
        searchQuery: '',
      ),
    );
    loadPolicies(page: 1, search: '');
  }

  Future<List<RoleDtoEntity>> searchRoles(
    String query,
    int page, {
    int size = 10,
  }) async {
    final res = await getRolesUseCase(page: page, size: size, search: query);
    return res.fold((_) => [], (roles) => roles);
  }

  Future<List<UserDtoEntity>> searchUsers(
    String query,
    int page, {
    int size = 10,
  }) async {
    final res = await getUsersUseCase(page: page, size: size, search: query);
    return res.fold((_) => [], (users) => users);
  }

  void setSelectedModule(String module) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    emit(
      currentState.copyWith(
        selectedModule: module,
        modifiedPolicies: const {},
        searchQuery: '',
      ),
    );
    loadPolicies(page: 1, search: '');
  }

  void togglePolicy(String permissionCode) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    PolicyEntity? targetPolicy;
    final updatedItems = currentState.paginatedPolicies.items.map((p) {
      if (p.permissionCode == permissionCode) {
        final newEnabled = !p.enabled;
        final updated = p.copyWith(
          enabled: newEnabled,
          effect: (newEnabled && p.effect.isEmpty) ? 'ALLOW' : p.effect,
        );
        targetPolicy = updated;
        return updated;
      }
      return p;
    }).toList();

    final updatedModified = Map<String, PolicyEntity>.from(
      currentState.modifiedPolicies,
    );
    if (targetPolicy != null) {
      updatedModified[permissionCode] = targetPolicy!;
    }

    emit(
      currentState.copyWith(
        paginatedPolicies: currentState.paginatedPolicies.copyWith(
          items: updatedItems,
        ),
        modifiedPolicies: updatedModified,
      ),
    );
  }

  void openConditionBuilder(String permissionCode) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    emit(currentState.copyWith(activeConditionPermission: permissionCode));
  }

  void closeConditionBuilder() {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    emit(currentState.copyWith(clearActivePermission: true));
  }

  void updatePolicyConditions(
    String permissionCode,
    Map<String, dynamic>? expressionJson,
    bool useCustomRego,
    String customRegoSnippet,
  ) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    PolicyEntity? targetPolicy;
    final updatedItems = currentState.paginatedPolicies.items.map((p) {
      if (p.permissionCode == permissionCode) {
        final updated = p.copyWith(
          enabled: true,
          effect: p.effect.isEmpty ? 'ALLOW' : p.effect,
          expressionJson: expressionJson,
          clearExpressionJson: expressionJson == null,
          useCustomRego: useCustomRego,
          customRegoSnippet: customRegoSnippet,
          clearCustomRegoSnippet: !useCustomRego || customRegoSnippet.isEmpty,
        );
        targetPolicy = updated;
        return updated;
      }
      return p;
    }).toList();

    final updatedModified = Map<String, PolicyEntity>.from(
      currentState.modifiedPolicies,
    );
    if (targetPolicy != null) {
      updatedModified[permissionCode] = targetPolicy!;
    }

    emit(
      currentState.copyWith(
        paginatedPolicies: currentState.paginatedPolicies.copyWith(
          items: updatedItems,
        ),
        modifiedPolicies: updatedModified,
        clearActivePermission: true,
      ),
    );
  }

  Future<String?> savePolicies() async {
    if (state is! PolicyLoaded) return null;
    final currentState = state as PolicyLoaded;

    emit(currentState.copyWith(isSaving: true, clearSaveError: true));

    // Combine all enabled policies:
    // Take all enabled policies from the current page, and merge any modified policies that are enabled
    final policyMap = <String, PolicyEntity>{};
    for (final p in currentState.paginatedPolicies.items) {
      if (p.enabled) {
        policyMap[p.permissionCode] = p;
      }
    }
    for (final p in currentState.modifiedPolicies.values) {
      if (p.enabled) {
        policyMap[p.permissionCode] = p;
      } else {
        policyMap.remove(p.permissionCode);
      }
    }

    final enabledPolicies = policyMap.values.toList();

    try {
      final result = await savePoliciesUseCase(
        subjectType: currentState.subjectType,
        subjectId: currentState.subjectId,
        namespace: currentState.selectedModule,
        policies: enabledPolicies,
      );

      return result.fold(
        (failure) {
          final latestState = state is PolicyLoaded
              ? (state as PolicyLoaded)
              : currentState;
          emit(
            latestState.copyWith(isSaving: false, saveError: failure.message),
          );
          return null;
        },
        (message) {
          final latestState = state is PolicyLoaded
              ? (state as PolicyLoaded)
              : currentState;
          emit(
            latestState.copyWith(
              isSaving: false,
              clearSaveError: true,
              modifiedPolicies: const {},
            ),
          );
          loadPolicies();
          return message;
        },
      );
    } catch (e) {
      final latestState = state is PolicyLoaded
          ? (state as PolicyLoaded)
          : currentState;
      emit(latestState.copyWith(isSaving: false, saveError: e.toString()));
      return null;
    }
  }

  void clearSaveError() {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    if (currentState.saveError != null) {
      emit(currentState.copyWith(clearSaveError: true));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
