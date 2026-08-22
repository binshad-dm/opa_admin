import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/field_definition_entity.dart';
import '../../domain/entities/policy_entity.dart';
import '../../domain/entities/role_dto_entity.dart';
import '../../domain/entities/user_dto_entity.dart';
import '../../domain/repositories/policy_repository.dart';
import '../datasources/policy_remote_data_source.dart';
import '../models/policy_model.dart';

class PolicyRepositoryImpl implements PolicyRepository {
  final PolicyRemoteDataSource remoteDataSource;

  PolicyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PolicyEntity>>> getPolicies({
    required String subjectType,
    required String subjectId,
    required String namespace,
  }) async {
    try {
      final policies = await remoteDataSource.fetchPolicies(
        subjectType,
        subjectId,
        namespace,
      );
      return Right(policies);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to load policies'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> savePolicies({
    required String subjectType,
    required String subjectId,
    required String namespace,
    required List<PolicyEntity> policies,
  }) async {
    try {
      final models = policies.map((p) => PolicyModel.fromEntity(p)).toList();
      final message = await remoteDataSource.savePolicies(
        subjectType,
        subjectId,
        namespace,
        models,
      );
      return Right(message);
    } on DioException catch (e) {
      String msg = 'Failed to save policies';
      if (e.response?.data != null && e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FieldDefinitionEntity>>> getFields({
    required String permissionCode,
  }) async {
    try {
      final fields = await remoteDataSource.fetchFields(permissionCode);
      return Right(fields);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to load fields'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoleDtoEntity>>> getRoles() async {
    try {
      final roles = await remoteDataSource.fetchRoles();
      return Right(roles);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserDtoEntity>>> getUsers() async {
    try {
      final users = await remoteDataSource.fetchUsers();
      return Right(users);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getNamespaces() async {
    try {
      // Query microservices on ports 8081, 8082, 8083
      final financeMods = await remoteDataSource.fetchNamespaces(8081);
      final clinicMods = await remoteDataSource.fetchNamespaces(8082);
      final pharmacyMods = await remoteDataSource.fetchNamespaces(8083);

      final combined = <String>{
        ...financeMods,
        ...clinicMods,
        ...pharmacyMods,
      }.toList();

      if (combined.isEmpty) {
        return const Right(['finance', 'clinical', 'pharmacy']);
      }
      return Right(combined);
    } catch (_) {
      return const Right(['finance', 'clinical', 'pharmacy']);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDynamicOptions({
    required String permissionCode,
    required String endpoint,
    required int page,
    required String search,
  }) async {
    try {
      final result = await remoteDataSource.fetchOptionsEndpoint(
        permissionCode,
        endpoint,
        page,
        search,
      );
      return Right(result);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
