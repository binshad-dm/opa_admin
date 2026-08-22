import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/policy_repository.dart';

class GetNamespacesUseCase {
  final PolicyRepository repository;

  GetNamespacesUseCase(this.repository);

  Future<Either<Failure, List<String>>> call() {
    return repository.getNamespaces();
  }
}
