import 'package:dio/dio.dart';

import '../../../../app/env/env.dart';
import '../../../../core/network/endpoints/policy_endpoints.dart';
import '../models/dynamic_option_model.dart';
import '../models/field_definition_model.dart';
import '../models/policy_model.dart';
import '../models/role_dto_model.dart';
import '../models/user_dto_model.dart';

abstract class PolicyRemoteDataSource {
  Future<List<PolicyModel>> fetchPolicies(
    String subjectType,
    String subjectId,
    String namespace,
  );

  Future<String> savePolicies(
    String subjectType,
    String subjectId,
    String namespace,
    List<PolicyModel> policies,
  );

  Future<List<FieldDefinitionModel>> fetchFields(String permissionCode);

  Future<List<RoleDtoModel>> fetchRoles();

  Future<List<UserDtoModel>> fetchUsers();

  Future<List<String>> fetchNamespaces(int microservicePort);

  Future<Map<String, dynamic>> fetchOptionsEndpoint(
    String permissionCode,
    String endpoint,
    int page,
    String search,
  );
}

class PolicyRemoteDataSourceImpl implements PolicyRemoteDataSource {
  final Dio dio;
  final Env env;

  PolicyRemoteDataSourceImpl({required this.dio, required this.env});

  String _getApiBaseUrl(String? identifier) {
    final base = env.apiBaseUrl;
    final uri = Uri.parse(base);
    int port = 8081;

    if (identifier != null && identifier.isNotEmpty) {
      if (identifier.startsWith('clinical') ||
          identifier.startsWith('billing')) {
        port = 8082;
      } else if (identifier.startsWith('finance')) {
        port = 8081;
      } else if (identifier.startsWith('pharmacy')) {
        port = 8083;
      }
    }
    return '${uri.scheme}://${uri.host}:$port';
  }

  String _getIdentityBaseUrl() {
    final base = env.authBaseUrl;
    final uri = Uri.parse(base);
    return '${uri.scheme}://${uri.host}:8085';
  }

  @override
  Future<List<PolicyModel>> fetchPolicies(
    String subjectType,
    String subjectId,
    String namespace,
  ) async {
    final baseUrl = _getApiBaseUrl(namespace);
    final url =
        '$baseUrl${PolicyEndpoints.policies}?subjectType=$subjectType&subjectId=$subjectId&namespace=$namespace';

    final response = await dio.get(url);
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data is List
          ? response.data
          : (response.data['policies'] ?? []);
      return list
          .map((e) => PolicyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to fetch policies',
    );
  }

  @override
  Future<String> savePolicies(
    String subjectType,
    String subjectId,
    String namespace,
    List<PolicyModel> policies,
  ) async {
    final baseUrl = _getApiBaseUrl(namespace);
    final url = '$baseUrl${PolicyEndpoints.policies}';

    final payload = {
      'subjectType': subjectType,
      'subjectId': subjectId,
      'namespace': namespace,
      'policies': policies.map((p) => p.toJson()).toList(),
    };

    final response = await dio.put(url, data: payload);
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.data != null) {
        if (response.data is Map && response.data['message'] != null) {
          return response.data['message'].toString();
        } else if (response.data is String && (response.data as String).isNotEmpty) {
          return response.data as String;
        }
      }
      return 'Policies saved successfully!';
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to save policies',
    );
  }

  @override
  Future<List<FieldDefinitionModel>> fetchFields(String permissionCode) async {
    final baseUrl = _getApiBaseUrl(permissionCode);
    final url = '$baseUrl${PolicyEndpoints.fields(permissionCode)}';

    final response = await dio.get(url);
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data is List ? response.data : [];
      return list
          .map((e) => FieldDefinitionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<RoleDtoModel>> fetchRoles() async {
    final baseUrl = _getIdentityBaseUrl();
    final url = '$baseUrl${PolicyEndpoints.roles}';

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        final List<dynamic> list = rawData is List
            ? rawData
            : (rawData['content'] as List<dynamic>? ?? []);
        return list
            .map((e) => RoleDtoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<UserDtoModel>> fetchUsers() async {
    final baseUrl = _getIdentityBaseUrl();
    final url = '$baseUrl${PolicyEndpoints.users}';

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        final List<dynamic> list = rawData is List
            ? rawData
            : (rawData['content'] as List<dynamic>? ?? []);
        return list
            .map((e) => UserDtoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<String>> fetchNamespaces(int microservicePort) async {
    final base = env.apiBaseUrl;
    final uri = Uri.parse(base);
    final url =
        '${uri.scheme}://${uri.host}:$microservicePort${PolicyEndpoints.namespaces}';

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data is List ? response.data : [];
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>> fetchOptionsEndpoint(
    String permissionCode,
    String endpoint,
    int page,
    String search,
  ) async {
    final baseUrl = _getApiBaseUrl(permissionCode);
    final queryParams = <String, dynamic>{
      'page': page,
      'size': 20,
      if (search.isNotEmpty) 'search': search,
    };

    try {
      final response = await dio.get(
        '$baseUrl$endpoint',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final contentRaw = data['content'] as List<dynamic>? ?? [];
          final items = contentRaw
              .map(
                (e) => DynamicOptionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          return {
            'content': items,
            'last': data['last'] as bool? ?? true,
            'page': data['number'] as int? ?? page,
          };
        }
      }
    } catch (_) {}
    return {'content': <DynamicOptionModel>[], 'last': true, 'page': page};
  }
}
