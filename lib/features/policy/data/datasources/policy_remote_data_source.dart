import 'package:dio/dio.dart';

import '../../../../app/env/env.dart';
import '../../../../core/network/endpoints/policy_endpoints.dart';
import '../models/dynamic_option_model.dart';
import '../models/field_definition_model.dart';
import '../models/policy_model.dart';
import '../models/role_dto_model.dart';
import '../models/user_dto_model.dart';

import '../../../../shared/component/pagination_component.dart';

abstract class PolicyRemoteDataSource {
  Future<PaginatedData<PolicyModel>> fetchPolicies(
    String subjectType,
    String subjectId,
    String namespace, {
    int page = 1,
    int size = 10,
    String? search,
  });

  Future<String> savePolicies(
    String subjectType,
    String subjectId,
    String namespace,
    List<PolicyModel> policies,
  );

  Future<List<FieldDefinitionModel>> fetchFields(String permissionCode);

  Future<List<RoleDtoModel>> fetchRoles({
    int page = 1,
    int size = 10,
    String? search,
  });

  Future<List<UserDtoModel>> fetchUsers({
    int page = 1,
    int size = 10,
    String? search,
  });

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
      } else if (identifier.startsWith('identity')) {
        port = 8085;
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
  Future<PaginatedData<PolicyModel>> fetchPolicies(
    String subjectType,
    String subjectId,
    String namespace, {
    int page = 1,
    int size = 10,
    String? search,
  }) async {
    final baseUrl = _getApiBaseUrl(namespace);
    final queryParams = <String, dynamic>{
      'subjectType': subjectType,
      'subjectId': subjectId,
      'namespace': namespace,
      'page': page,
      'size': size,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final response = await dio.get(
      '$baseUrl${PolicyEndpoints.policies}',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['content'] != null) {
        final List<dynamic> list = data['content'] as List<dynamic>? ?? [];
        final items = list
            .map((e) => PolicyModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawPageNumber = data['pageNumber'] ?? data['number'];
        int pageNumber = 1;
        if (rawPageNumber is int) {
          pageNumber = rawPageNumber;
        } else if (rawPageNumber != null) {
          pageNumber = int.tryParse(rawPageNumber.toString()) ?? 1;
        }

        final rawPageSize = data['pageSize'] ?? data['size'] ?? size;
        int pageSize = size;
        if (rawPageSize is int) {
          pageSize = rawPageSize;
        } else if (rawPageSize != null) {
          pageSize = int.tryParse(rawPageSize.toString()) ?? size;
        }

        final rawTotalElements = data['totalElements'] ?? items.length;
        int totalElements = items.length;
        if (rawTotalElements is int) {
          totalElements = rawTotalElements;
        } else if (rawTotalElements != null) {
          totalElements =
              int.tryParse(rawTotalElements.toString()) ?? items.length;
        }

        final rawTotalPages = data['totalPages'];
        int totalPages = 1;
        if (rawTotalPages is int) {
          totalPages = rawTotalPages;
        } else if (rawTotalPages != null) {
          totalPages = int.tryParse(rawTotalPages.toString()) ?? 1;
        } else if (pageSize > 0) {
          totalPages = (totalElements / pageSize).ceil();
        }

        return PaginatedData<PolicyModel>(
          items: items,
          totalItems: totalElements,
          currentPage: pageNumber,
          totalPages: totalPages > 0 ? totalPages : 1,
          itemsPerPage: pageSize,
        );
      } else {
        // Fallback for raw List or { policies: [...] }
        final List<dynamic> list = data is List
            ? data
            : (data is Map ? (data['policies'] ?? []) : []);
        final allItems = list
            .map((e) => PolicyModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return PaginatedData<PolicyModel>(
          items: allItems,
          totalItems: allItems.length,
          currentPage: 1,
          totalPages: 1,
          itemsPerPage: allItems.isNotEmpty ? allItems.length : 10,
        );
      }
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
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (response.data != null) {
        if (response.data is Map && response.data['message'] != null) {
          return response.data['message'].toString();
        } else if (response.data is String &&
            (response.data as String).isNotEmpty) {
          return response.data as String;
        }
      }
      return 'Policies saved successfully!';
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: response.data?.toString() ?? 'Failed to save policies',
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
  Future<List<RoleDtoModel>> fetchRoles({
    int page = 1,
    int size = 10,
    String? search,
  }) async {
    final baseUrl = _getIdentityBaseUrl();
    final url = '$baseUrl${PolicyEndpoints.roles}';
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    try {
      final response = await dio.get(url, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        final List<dynamic> list = rawData is List
            ? rawData
            : (rawData['content'] as List<dynamic>? ?? []);
        var items = list
            .map((e) => RoleDtoModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (rawData is List && search != null && search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          items = items
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    (r.description?.toLowerCase().contains(q) ?? false),
              )
              .toList();
        }
        return items;
      }
    } catch (_) {}

    // Fallback to local microservice projected subjects endpoint
    try {
      final fallbackUrl =
          '${_getApiBaseUrl('pharmacy')}/internal/authz/subjects?type=ROLE';
      final response = await dio.get(fallbackUrl, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        final List<dynamic> list = rawData is List
            ? rawData
            : (rawData['content'] as List<dynamic>? ?? []);
        var items = list
            .map((e) => RoleDtoModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (search != null && search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          items = items
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    (r.description?.toLowerCase().contains(q) ?? false),
              )
              .toList();
        }
        final startIndex = (page - 1) * size;
        if (startIndex >= items.length) return [];
        final endIndex = (startIndex + size).clamp(0, items.length);
        return items.sublist(startIndex, endIndex);
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<List<UserDtoModel>> fetchUsers({
    int page = 1,
    int size = 10,
    String? search,
  }) async {
    final baseUrl = _getIdentityBaseUrl();
    final url = '$baseUrl${PolicyEndpoints.users}';
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    try {
      final response = await dio.get(url, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        final List<dynamic> list = rawData is List
            ? rawData
            : (rawData['content'] as List<dynamic>? ?? []);
        var items = list
            .map((e) => UserDtoModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (rawData is List && search != null && search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          items = items
              .where(
                (u) =>
                    u.displayName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q),
              )
              .toList();
        }
        return items;
      }
    } catch (_) {}

    // Fallback to local microservice projected subjects endpoint
    try {
      final fallbackUrl =
          '${_getApiBaseUrl('pharmacy')}/internal/authz/subjects?type=USER';
      final response = await dio.get(fallbackUrl, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        final List<dynamic> list = rawData is List
            ? rawData
            : (rawData['content'] as List<dynamic>? ?? []);
        var items = list
            .map((e) => UserDtoModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (search != null && search.trim().isNotEmpty) {
          final q = search.trim().toLowerCase();
          items = items
              .where(
                (u) =>
                    u.displayName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q),
              )
              .toList();
        }
        final startIndex = (page - 1) * size;
        if (startIndex >= items.length) return [];
        final endIndex = (startIndex + size).clamp(0, items.length);
        return items.sublist(startIndex, endIndex);
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
