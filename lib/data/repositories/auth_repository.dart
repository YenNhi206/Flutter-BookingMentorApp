import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/token_storage.dart';
import '../../models/user_profile.dart';

/// Kept as a distinct type (rather than just using [ApiException] directly)
/// so existing call sites that catch/display auth errors don't need to change.
class AuthException extends ApiException {
  AuthException(super.message);
}

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    try {
      await _apiClient.post(
        '/auth/register',
        body: {'name': name, 'email': email, 'password': password},
        auth: false,
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
    // /auth/register doesn't return tokens (only /auth/login does), so log
    // the freshly-registered account in immediately for a seamless signup flow.
    return login(email: email, password: password);
  }

  Future<UserProfile> login({required String email, required String password}) async {
    try {
      final result = await _apiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
        auth: false,
      ) as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: result['token'] as String,
        refreshToken: result['refreshToken'] as String,
      );
      return UserProfile.fromJson(result['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Checks for a stored session and validates it against the backend.
  /// Returns null (and clears any stored tokens) if there is no valid
  /// session - also fails safe to "no session" if reading from secure
  /// storage itself throws (e.g. no platform implementation available).
  Future<UserProfile?> tryRestoreSession() async {
    try {
      final token = await _tokenStorage.accessToken;
      if (token == null) return null;
      final result = await _apiClient.get('/auth/me') as Map<String, dynamic>;
      return UserProfile.fromJson(result['user'] as Map<String, dynamic>);
    } catch (_) {
      await _tokenStorage.clear().catchError((_) {});
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // best-effort - still clear the local session even if the call fails
    }
    await _tokenStorage.clear();
  }

  Future<List<UserProfile>> getAll() async {
    final result = await _apiClient.get('/admin/users') as Map<String, dynamic>;
    final users = result['users'] as List<dynamic>;
    return users.map((u) => UserProfile.fromJson(u as Map<String, dynamic>)).toList();
  }

  Future<void> updateActive(String userId, bool isActive) async {
    await _apiClient.patch('/admin/users/$userId/status', body: {'isActive': isActive});
  }

  Future<UserProfile> updateProfile(UserProfile updated) async {
    final result = await _apiClient.patch(
      '/auth/me',
      body: {'name': updated.name, 'phone': updated.phone},
    ) as Map<String, dynamic>;
    return UserProfile.fromJson(result['user'] as Map<String, dynamic>);
  }
}
