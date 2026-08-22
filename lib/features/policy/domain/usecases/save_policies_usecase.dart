import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/policy_entity.dart';
import '../repositories/policy_repository.dart';

class SavePoliciesUseCase {
  final PolicyRepository repository;

  SavePoliciesUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String subjectType,
    required String subjectId,
    required String namespace,
    required List<PolicyEntity> policies,
  }) {
    return repository.savePolicies(
      subjectType: subjectType,
      subjectId: subjectId,
      namespace: namespace,
      policies: policies,
    );
  }
}
