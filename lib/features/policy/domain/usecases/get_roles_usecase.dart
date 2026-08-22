import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/role_dto_entity.dart';
import '../repositories/policy_repository.dart';

class GetRolesUseCase {
  final PolicyRepository repository;

  GetRolesUseCase(this.repository);

  Future<Either<Failure, List<RoleDtoEntity>>> call() {
    return repository.getRoles();
  }
}
