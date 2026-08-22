import 'package:flutter_bloc/flutter_bloc.dart';

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
    String subjectId = roles.isNotEmpty ? roles.first.name : '';
    String moduleName = modules.isNotEmpty ? modules.first : 'finance';

    if (subjectId.isEmpty && users.isNotEmpty) {
      subjectType = 'USER';
      subjectId = users.first.email;
    }

    if (subjectId.isNotEmpty) {
      final policiesRes = await getPoliciesUseCase(
        subjectType: subjectType,
        subjectId: subjectId,
        namespace: moduleName,
      );

      List<PolicyEntity> policies = [];
      policiesRes.fold((_) {}, (p) => policies = p);

      emit(PolicyLoaded(
        subjectType: subjectType,
        subjectId: subjectId,
        selectedModule: moduleName,
        availableModules: modules,
        roles: roles,
        users: users,
        policies: policies,
      ));
    } else {
      emit(PolicyLoaded(
        subjectType: subjectType,
        subjectId: subjectId,
        selectedModule: moduleName,
        availableModules: modules,
        roles: roles,
        users: users,
        policies: const [],
      ));
    }
  }

  Future<void> loadPolicies() async {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    if (currentState.subjectId.isEmpty) {
      emit(currentState.copyWith(policies: []));
      return;
    }

    emit(currentState.copyWith(isSaving: false));

    final result = await getPoliciesUseCase(
      subjectType: currentState.subjectType,
      subjectId: currentState.subjectId,
      namespace: currentState.selectedModule,
    );

    result.fold(
      (failure) => emit(PolicyError(failure.message)),
      (policies) => emit(currentState.copyWith(policies: policies)),
    );
  }

  void setSubjectType(String newType) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    String newSubjectId = '';
    if (newType == 'ROLE' && currentState.roles.isNotEmpty) {
      newSubjectId = currentState.roles.first.name;
    } else if (newType == 'USER' && currentState.users.isNotEmpty) {
      newSubjectId = currentState.users.first.email;
    }

    emit(currentState.copyWith(
      subjectType: newType,
      subjectId: newSubjectId,
    ));

    loadPolicies();
  }

  void setSubjectId(String id) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    emit(currentState.copyWith(subjectId: id));
    loadPolicies();
  }

  void setSelectedModule(String module) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;
    emit(currentState.copyWith(selectedModule: module));
    loadPolicies();
  }

  void togglePolicy(String permissionCode) {
    if (state is! PolicyLoaded) return;
    final currentState = state as PolicyLoaded;

    final updatedPolicies = currentState.policies.map((p) {
      if (p.permissionCode == permissionCode) {
        final newEnabled = !p.enabled;
        return p.copyWith(
          enabled: newEnabled,
          effect: (newEnabled && p.effect.isEmpty) ? 'ALLOW' : p.effect,
        );
      }
      return p;
    }).toList();

    emit(currentState.copyWith(policies: updatedPolicies));
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

    final updated = currentState.policies.map((p) {
      if (p.permissionCode == permissionCode) {
        return p.copyWith(
          enabled: true,
          effect: p.effect.isEmpty ? 'ALLOW' : p.effect,
          expressionJson: expressionJson,
          useCustomRego: useCustomRego,
          customRegoSnippet: customRegoSnippet,
        );
      }
      return p;
    }).toList();

    emit(currentState.copyWith(
      policies: updated,
      clearActivePermission: true,
    ));
  }

  Future<String?> savePolicies() async {
    if (state is! PolicyLoaded) return null;
    final currentState = state as PolicyLoaded;

    emit(currentState.copyWith(isSaving: true, saveError: null));

    final enabledPolicies = currentState.policies.where((p) => p.enabled).toList();

    final result = await savePoliciesUseCase(
      subjectType: currentState.subjectType,
      subjectId: currentState.subjectId,
      namespace: currentState.selectedModule,
      policies: enabledPolicies,
    );

    return result.fold(
      (failure) {
        emit(currentState.copyWith(
          isSaving: false,
          saveError: failure.message,
        ));
        return null;
      },
      (message) {
        emit(currentState.copyWith(isSaving: false));
        return message;
      },
    );
  }
}
