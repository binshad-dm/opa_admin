import 'package:equatable/equatable.dart';

import '../../../../shared/component/pagination_component.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/entities/role_dto_entity.dart';
import '../../domain/entities/user_dto_entity.dart';

abstract class PolicyState extends Equatable {
  const PolicyState();

  @override
  List<Object?> get props => [];
}

class PolicyInitial extends PolicyState {}

class PolicyLoading extends PolicyState {
  final String? message;
  const PolicyLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class PolicyLoaded extends PolicyState {
  final String subjectType; // ROLE or USER
  final String subjectId;
  final String selectedModule; // finance, clinical, pharmacy, etc.
  final List<String> availableModules;
  final List<RoleDtoEntity> roles;
  final List<UserDtoEntity> users;
  final PaginatedData<PolicyEntity> paginatedPolicies;
  final String searchQuery;
  final String? activeConditionPermission;
  final bool isSaving;
  final String? saveError;
  final Map<String, PolicyEntity> modifiedPolicies;

  List<PolicyEntity> get policies => paginatedPolicies.items;

  PolicyLoaded({
    required this.subjectType,
    required this.subjectId,
    required this.selectedModule,
    required this.availableModules,
    required this.roles,
    required this.users,
    PaginatedData<PolicyEntity>? paginatedPolicies,
    List<PolicyEntity>? policies,
    this.searchQuery = '',
    this.activeConditionPermission,
    this.isSaving = false,
    this.saveError,
    this.modifiedPolicies = const {},
  }) : paginatedPolicies = paginatedPolicies ??
            PaginatedData<PolicyEntity>(
              items: policies ?? const [],
              totalItems: (policies ?? const []).length,
              currentPage: 1,
              totalPages: 1,
              itemsPerPage: (policies != null && policies.isNotEmpty)
                  ? policies.length
                  : 10,
            );

  PolicyLoaded copyWith({
    String? subjectType,
    String? subjectId,
    String? selectedModule,
    List<String>? availableModules,
    List<RoleDtoEntity>? roles,
    List<UserDtoEntity>? users,
    PaginatedData<PolicyEntity>? paginatedPolicies,
    List<PolicyEntity>? policies,
    String? searchQuery,
    String? activeConditionPermission,
    bool? isSaving,
    String? saveError,
    Map<String, PolicyEntity>? modifiedPolicies,
    bool clearActivePermission = false,
    bool clearSaveError = false,
  }) {
    return PolicyLoaded(
      subjectType: subjectType ?? this.subjectType,
      subjectId: subjectId ?? this.subjectId,
      selectedModule: selectedModule ?? this.selectedModule,
      availableModules: availableModules ?? this.availableModules,
      roles: roles ?? this.roles,
      users: users ?? this.users,
      paginatedPolicies: paginatedPolicies ??
          (policies != null
              ? this.paginatedPolicies.copyWith(items: policies)
              : this.paginatedPolicies),
      searchQuery: searchQuery ?? this.searchQuery,
      activeConditionPermission: clearActivePermission
          ? null
          : (activeConditionPermission ?? this.activeConditionPermission),
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      modifiedPolicies: modifiedPolicies ?? this.modifiedPolicies,
    );
  }

  @override
  List<Object?> get props => [
        subjectType,
        subjectId,
        selectedModule,
        availableModules,
        roles,
        users,
        paginatedPolicies,
        searchQuery,
        activeConditionPermission,
        isSaving,
        saveError,
        modifiedPolicies,
      ];
}

class PolicyError extends PolicyState {
  final String message;
  const PolicyError(this.message);

  @override
  List<Object?> get props => [message];
}

class PolicySaveSuccess extends PolicyState {
  final String message;
  const PolicySaveSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
