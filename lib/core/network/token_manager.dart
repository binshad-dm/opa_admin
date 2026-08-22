import '../storage/secure_store.dart';
import 'token_pair.dart';

class TokenManager {
  final SecureStore _s;
  static const _A = 'auth_access_token';
  static const _R = 'auth_refresh_token';
  TokenManager(this._s);
  Future<void> save(TokenPair p) async {
    await _s.write(_A, p.accessToken);
    await _s.write(_R, p.refreshToken);
  }

  Future<String?> getAccess() => _s.read(_A);
  Future<String?> getRefresh() => _s.read(_R);
  Future<void> clear() async {
    await _s.delete(_A);
    await _s.delete(_R);
  }
}
