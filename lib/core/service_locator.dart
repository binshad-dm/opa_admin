import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:opa_admin/core/shared/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/env/env.dart';
import 'storage/secure_store.dart';
import 'storage/secure_store_impl.dart';
import 'print/i_print_handler.dart';
import 'print/print_handler_factory.dart';
import 'network/tenant_manager.dart';
import 'network/token_manager.dart';
import 'network/user_context.dart';
import 'network/app_dio_client.dart';
import 'network/auth_api.dart';
import 'package:flutter/foundation.dart';
import '../features/policy/data/datasources/policy_remote_data_source.dart';
import '../features/policy/data/repositories/policy_repository_impl.dart';
import '../features/policy/domain/repositories/policy_repository.dart';
import '../features/policy/domain/usecases/get_dynamic_options_usecase.dart';
import '../features/policy/domain/usecases/get_fields_usecase.dart';
import '../features/policy/domain/usecases/get_namespaces_usecase.dart';
import '../features/policy/domain/usecases/get_policies_usecase.dart';
import '../features/policy/domain/usecases/get_roles_usecase.dart';
import '../features/policy/domain/usecases/get_users_usecase.dart';
import '../features/policy/domain/usecases/save_policies_usecase.dart';
import '../features/policy/presentation/view_model/condition_builder_cubit.dart';
import '../features/policy/presentation/view_model/policy_cubit.dart';


final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Environment
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final env = Env.fromFlavor(flavor);
  sl.registerSingleton<Env>(env);

  // Core Services
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<SecureStore>(() => SecureStoreImpl());

  sl.registerLazySingleton<PrintHandler>(() => PrintHandlerImpl());

  sl.registerLazySingleton<TenantManager>(
    () => TenantManager(sl<SecureStore>()),
  );

  sl.registerSingleton<UserContext>(UserContext());

  sl.registerLazySingleton<NotificationManager>(() => NotificationManager());

  // HTTP Clients
  sl.registerLazySingleton<TokenManager>(() => TokenManager(sl<SecureStore>()));

  // Auth Dio (port 8085)
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: sl<Env>().authBaseUrl,
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 5000),
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    return dio;
  }, instanceName: 'auth');

  // AuthApi
  sl.registerLazySingleton<AuthApi>(
    () => AuthApi(sl<Dio>(instanceName: 'auth')),
  );

  // Main Dio
  sl.registerLazySingleton<Dio>(() {
    final dioClient = AppDioClient(
      sl<Env>(),
      tokenManager: sl<TokenManager>(),
      tenantManager: sl<TenantManager>(),
      userContext: sl<UserContext>(),
      authApi: sl<AuthApi>(),
    );
    return dioClient.dio;
  });


  // User-module Dio — targets port 8081
  sl.registerLazySingleton<Dio>(() {
    final mainBaseUrl = sl<Env>().apiBaseUrl;
    // Replace port 8080 with 8081 for the user-module server
    final userBaseUrl = mainBaseUrl.replaceAll(':8080', ':8085');

    final dioClient = AppDioClient(
      authApi: sl<AuthApi>(),
      Env(
        apiBaseUrl: userBaseUrl,
        enableLogging: sl<Env>().enableLogging,
        flavor: sl<Env>().flavor,
        authBaseUrl: sl<Env>().authBaseUrl,
      ),
      tokenManager: sl<TokenManager>(),
      tenantManager: sl<TenantManager>(),
      userContext: sl<UserContext>(),
    );
    return dioClient.dio;
  }, instanceName: 'userDio');

  // Role-module Dio — targets port 8085
  sl.registerLazySingleton<Dio>(() {
    final mainBaseUrl = sl<Env>().apiBaseUrl;
    // Replace port 8080 with 8085 for the role-module server
    final roleBaseUrl = mainBaseUrl.replaceAll(':8080', ':8085');

    final dioClient = AppDioClient(
      authApi: sl<AuthApi>(),
      Env(
        apiBaseUrl: roleBaseUrl,
        enableLogging: sl<Env>().enableLogging,
        flavor: sl<Env>().flavor,
        authBaseUrl: sl<Env>().authBaseUrl,
      ),
      tokenManager: sl<TokenManager>(),
      tenantManager: sl<TenantManager>(),
      userContext: sl<UserContext>(),
    );

    // Remove authorization header for roleDio requests
    dioClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.remove('Authorization');
          handler.next(options);
        },
      ),
    );

    return dioClient.dio;
  }, instanceName: 'roleDio');

  // APIs

  // Policy Feature
  sl.registerLazySingleton<PolicyRemoteDataSource>(
    () => PolicyRemoteDataSourceImpl(dio: sl<Dio>(), env: sl<Env>()),
  );
  sl.registerLazySingleton<PolicyRepository>(
    () => PolicyRepositoryImpl(remoteDataSource: sl<PolicyRemoteDataSource>()),
  );

  sl.registerLazySingleton(() => GetPoliciesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => SavePoliciesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetFieldsUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetRolesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetUsersUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetNamespacesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetDynamicOptionsUseCase(sl<PolicyRepository>()));

  sl.registerFactory(
    () => PolicyCubit(
      getPoliciesUseCase: sl(),
      savePoliciesUseCase: sl(),
      getRolesUseCase: sl(),
      getUsersUseCase: sl(),
      getNamespacesUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ConditionBuilderCubit(
      getFieldsUseCase: sl(),
    ),
  );
}

