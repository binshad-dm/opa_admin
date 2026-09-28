import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/env/env.dart';
import 'config/opa_config.dart';
import 'storage/secure_store.dart';
import 'storage/secure_store_impl.dart';
import 'print/i_print_handler.dart';
import 'print/print_handler_factory.dart';
import 'network/tenant_manager.dart';
import 'network/token_manager.dart';
import 'network/user_context.dart';
import 'network/app_dio_client.dart';
import 'network/auth_api.dart';
import 'shared/snackbar.dart';

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

/// Isolated dependency container for the OPA Admin package.
///
/// Using `GetIt.asNewInstance()` ensures this container is completely separated
/// from the host application's `GetIt.instance`, preventing collision errors.
final sl = GetIt.asNewInstance();

Future<void> initServiceLocator({OpaConfig? config}) async {
  // If already initialized, reset cleanly before re-registering
  if (sl.isRegistered<Env>() || sl.isRegistered<Dio>()) {
    await resetServiceLocator();
  }

  // Environment Configuration
  final Env env;
  if (config != null) {
    env = Env(
      apiBaseUrl: config.baseUrl,
      authBaseUrl: '',
      enableLogging: kDebugMode,
      flavor: 'prod',
    );
  } else {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    env = Env.fromFlavor(flavor);
  }
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

  // Token Manager: accepts external host callback if provided
  sl.registerLazySingleton<TokenManager>(
    () => TokenManager(sl<SecureStore>(), config?.getAccessToken),
  );

  // Auth Dio & AuthApi for fallback / legacy dev mode
  sl.registerLazySingleton<Dio>(() {
    final authUrl = sl<Env>().authBaseUrl.isNotEmpty
        ? sl<Env>().authBaseUrl
        : sl<Env>().apiBaseUrl;
    final dio = Dio(
      BaseOptions(
        baseUrl: authUrl,
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

  sl.registerLazySingleton<AuthApi>(
    () => AuthApi(sl<Dio>(instanceName: 'auth')),
  );

  // Main HTTP Client
  sl.registerLazySingleton<Dio>(() {
    final dioClient = AppDioClient(
      sl<Env>(),
      tokenManager: sl<TokenManager>(),
      tenantManager: sl<TenantManager>(),
      userContext: sl<UserContext>(),
      authApi: sl<AuthApi>(),
      opaConfig: config,
    );
    return dioClient.dio;
  });

  // Feature: Policy Data Layer
  sl.registerLazySingleton<PolicyRemoteDataSource>(
    () => PolicyRemoteDataSourceImpl(dio: sl<Dio>(), env: sl<Env>()),
  );
  sl.registerLazySingleton<PolicyRepository>(
    () => PolicyRepositoryImpl(remoteDataSource: sl<PolicyRemoteDataSource>()),
  );

  // Feature: Policy Use Cases
  sl.registerLazySingleton(() => GetPoliciesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => SavePoliciesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetFieldsUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetRolesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetUsersUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetNamespacesUseCase(sl<PolicyRepository>()));
  sl.registerLazySingleton(() => GetDynamicOptionsUseCase(sl<PolicyRepository>()));

  // Feature: Policy Cubits (Factory)
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

/// Clears all registrations and state in the isolated container.
Future<void> resetServiceLocator() async {
  await sl.reset();
}
