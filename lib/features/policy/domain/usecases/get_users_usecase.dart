import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/user_dto_entity.dart';
import '../repositories/policy_repository.dart';

class GetUsersUseCase {
  final PolicyRepository repository;

  GetUsersUseCase(this.repository);

  Future<Either<Failure, List<UserDtoEntity>>> call({
    int page = 1,
    int size = 10,
    String? search,
  }) {
    return repository.getUsers(page: page, size: size, search: search);
  }
}
