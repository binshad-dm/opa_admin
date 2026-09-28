import 'config/opa_config.dart';
import 'service_locator.dart';

/// Entry facade for the OPA Admin package.
///
/// Host applications should initialize this SDK once (e.g. after login or at app startup):
/// ```dart
/// await OpaAdmin.initialize(
///   config: OpaConfig(
///     baseUrl: 'https://api.yourdomain.com',
///     getAccessToken: () async => await myAuthStorage.getToken(),
///     onRefreshToken: () async => await myAuthStorage.refreshToken(),
///     onSessionExpired: () => myNavigator.pushReplacementNamed('/login'),
///   ),
/// );
/// ```
class OpaAdmin {
  static OpaConfig? _config;

  /// Returns the current configuration, or null if not yet initialized.
  static OpaConfig? get config => _config;

  /// Whether the SDK has been initialized with a valid configuration.
  static bool get isInitialized => _config != null;

  /// Initializes the OPA Admin SDK with the host app's configuration and sets up the internal isolated dependency container.
  static Future<void> initialize({required OpaConfig config}) async {
    _config = config;
    await initServiceLocator(config: config);
  }

  /// Cleans up cached state, repositories, and dependency instances inside the SDK upon host user logout.
  static Future<void> reset() async {
    await resetServiceLocator();
    _config = null;
  }
}
