import 'package:equatable/equatable.dart';

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
  final List<PolicyEntity> policies;
  final String? activeConditionPermission;
  final bool isSaving;
  final String? saveError;

  const PolicyLoaded({
    required this.subjectType,
    required this.subjectId,
    required this.selectedModule,
    required this.availableModules,
    required this.roles,
    required this.users,
    required this.policies,
    this.activeConditionPermission,
    this.isSaving = false,
    this.saveError,
  });

  PolicyLoaded copyWith({
    String? subjectType,
    String? subjectId,
    String? selectedModule,
    List<String>? availableModules,
    List<RoleDtoEntity>? roles,
    List<UserDtoEntity>? users,
    List<PolicyEntity>? policies,
    String? activeConditionPermission,
    bool? isSaving,
    String? saveError,
    bool clearActivePermission = false,
  }) {
    return PolicyLoaded(
      subjectType: subjectType ?? this.subjectType,
      subjectId: subjectId ?? this.subjectId,
      selectedModule: selectedModule ?? this.selectedModule,
      availableModules: availableModules ?? this.availableModules,
      roles: roles ?? this.roles,
      users: users ?? this.users,
      policies: policies ?? this.policies,
      activeConditionPermission: clearActivePermission
          ? null
          : (activeConditionPermission ?? this.activeConditionPermission),
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError,
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
        policies,
        activeConditionPermission,
        isSaving,
        saveError,
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
