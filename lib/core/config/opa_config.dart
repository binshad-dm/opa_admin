typedef TokenProvider = Future<String?> Function();
typedef RefreshTokenHandler = Future<String?> Function();
typedef SessionExpiredCallback = void Function();

/// Configuration contract supplied by the parent/host application
/// when initializing the OPA Admin package.
class OpaConfig {
  /// The backend API base URL for OPA Admin services (e.g., 'https://api.yourdomain.com')
  final String baseUrl;

  /// Callback supplied by the host app to retrieve the current active JWT
  final TokenProvider getAccessToken;

  /// Optional callback to trigger token refresh in the host app on 401 Unauthorized
  final RefreshTokenHandler? onRefreshToken;

  /// Optional callback invoked when the session is expired/unauthorized
  final SessionExpiredCallback? onSessionExpired;

  const OpaConfig({
    required this.baseUrl,
    required this.getAccessToken,
    this.onRefreshToken,
    this.onSessionExpired,
  });
}
