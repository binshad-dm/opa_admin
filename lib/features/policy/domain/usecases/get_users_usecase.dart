import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/user_dto_entity.dart';
import '../repositories/policy_repository.dart';

class GetUsersUseCase {
  final PolicyRepository repository;

  GetUsersUseCase(this.repository);

  Future<Either<Failure, List<UserDtoEntity>>> call() {
    return repository.getUsers();
  }
}
