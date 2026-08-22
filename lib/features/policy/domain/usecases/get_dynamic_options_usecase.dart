import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/policy_repository.dart';

class GetDynamicOptionsUseCase {
  final PolicyRepository repository;

  GetDynamicOptionsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String permissionCode,
    required String endpoint,
    required int page,
    required String search,
  }) {
    return repository.getDynamicOptions(
      permissionCode: permissionCode,
      endpoint: endpoint,
      page: page,
      search: search,
    );
  }
}
