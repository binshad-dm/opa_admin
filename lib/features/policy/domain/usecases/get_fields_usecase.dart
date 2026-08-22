import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/field_definition_entity.dart';
import '../repositories/policy_repository.dart';

class GetFieldsUseCase {
  final PolicyRepository repository;

  GetFieldsUseCase(this.repository);

  Future<Either<Failure, List<FieldDefinitionEntity>>> call(
      String permissionCode) {
    return repository.getFields(permissionCode: permissionCode);
  }
}
