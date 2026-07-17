import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

enum AuthStatus { unknown, authenticated, guest, unauthenticated }

/// ViewModel quản lý trạng thái đăng nhập toàn app - tương đương "session
/// state" mà [SplashScreen] đọc để quyết định điều hướng, và mọi màn hình
/// khác đọc để biết user hiện tại là ai.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final SessionService _sessionService;

  AuthViewModel({AuthService? authService, SessionService? sessionService})
      : _authService = authService ?? AuthService(),
        _sessionService = sessionService ?? SessionService();

  AppUser? currentUser;
  AuthStatus status = AuthStatus.unknown;
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;

  /// Kiểm tra phiên đăng nhập đã lưu từ lần mở app trước - gọi ở
  /// [SplashScreen] khi khởi động.
  Future<void> restoreSession() async {
    final userId = await _sessionService.getUserId();
    if (userId != null) {
      final user = await _authService.getById(userId);
      if (user != null) {
        currentUser = user;
        status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    }
    final guest = await _sessionService.isGuest();
    status = guest ? AuthStatus.guest : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.login(email: email, password: password);
      currentUser = user;
      status = AuthStatus.authenticated;
      await _sessionService.saveUserId(user.id);
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? storeName,
    String? storeAddress,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        storeName: storeName,
        storeAddress: storeAddress,
      );
      currentUser = user;
      status = AuthStatus.authenticated;
      await _sessionService.saveUserId(user.id);
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    status = AuthStatus.guest;
    currentUser = null;
    await _sessionService.saveGuestSession();
    notifyListeners();
  }

  /// Tra cứu 1 user bất kỳ theo id - dùng cho màn chat phía chủ quán để
  /// hiển thị tên khách, khác với [currentUser] (chỉ là user đang đăng nhập).
  Future<AppUser?> getUserById(String userId) => _authService.getById(userId);

  Future<void> updateProfile({String? fullName, String? phone, String? address}) async {
    if (currentUser == null) return;
    final updated = currentUser!.copyWith(fullName: fullName, phone: phone, address: address);
    currentUser = await _authService.updateProfile(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    status = AuthStatus.unauthenticated;
    await _sessionService.clear();
    notifyListeners();
  }
}
