import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/role_dto_entity.dart';
import '../repositories/policy_repository.dart';

class GetRolesUseCase {
  final PolicyRepository repository;

  GetRolesUseCase(this.repository);

  Future<Either<Failure, List<RoleDtoEntity>>> call({
    int page = 1,
    int size = 10,
    String? search,
  }) {
    return repository.getRoles(page: page, size: size, search: search);
  }
}
