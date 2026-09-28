import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/policy_entity.dart';
import '../repositories/policy_repository.dart';

import '../../../../shared/component/pagination_component.dart';

class GetPoliciesUseCase {
  final PolicyRepository repository;

  GetPoliciesUseCase(this.repository);

  Future<Either<Failure, PaginatedData<PolicyEntity>>> call({
    required String subjectType,
    required String subjectId,
    required String namespace,
    int page = 1,
    int size = 10,
    String? search,
  }) {
    return repository.getPolicies(
      subjectType: subjectType,
      subjectId: subjectId,
      namespace: namespace,
      page: page,
      size: size,
      search: search,
    );
  }
}
