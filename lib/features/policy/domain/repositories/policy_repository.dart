import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/field_definition_entity.dart';
import '../entities/policy_entity.dart';
import '../entities/role_dto_entity.dart';
import '../entities/user_dto_entity.dart';

abstract class PolicyRepository {
  Future<Either<Failure, List<PolicyEntity>>> getPolicies({
    required String subjectType,
    required String subjectId,
    required String namespace,
  });

  Future<Either<Failure, String>> savePolicies({
    required String subjectType,
    required String subjectId,
    required String namespace,
    required List<PolicyEntity> policies,
  });

  Future<Either<Failure, List<FieldDefinitionEntity>>> getFields({
    required String permissionCode,
  });

  Future<Either<Failure, List<RoleDtoEntity>>> getRoles();

  Future<Either<Failure, List<UserDtoEntity>>> getUsers();

  Future<Either<Failure, List<String>>> getNamespaces();

  Future<Either<Failure, Map<String, dynamic>>> getDynamicOptions({
    required String permissionCode,
    required String endpoint,
    required int page,
    required String search,
  });
}
