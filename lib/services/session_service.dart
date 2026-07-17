import 'package:shared_preferences/shared_preferences.dart';

/// Lưu id user đang đăng nhập vào [SharedPreferences] để app nhớ phiên đăng
/// nhập giữa các lần mở app (splash screen dùng giá trị này để quyết định
/// điều hướng thẳng vào Home hay ra Onboarding).
class SessionService {
  static const _keyUserId = 'session_user_id';
  static const _keyIsGuest = 'session_is_guest';

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyIsGuest, false);
  }

  Future<void> saveGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.setBool(_keyIsGuest, true);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyIsGuest);
  }
}
