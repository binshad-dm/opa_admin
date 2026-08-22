import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/policy_entity.dart';
import '../repositories/policy_repository.dart';

class GetPoliciesUseCase {
  final PolicyRepository repository;

  GetPoliciesUseCase(this.repository);

  Future<Either<Failure, List<PolicyEntity>>> call({
    required String subjectType,
    required String subjectId,
    required String namespace,
  }) {
    return repository.getPolicies(
      subjectType: subjectType,
      subjectId: subjectId,
      namespace: namespace,
    );
  }
}
