import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scoops/viewmodels/auth_vm.dart';
import 'package:scoops/views/screens/auth_screen.dart';

/// Fake thủ công thay cho mock: override [login]/[register] để không đụng
/// tới [AuthService]/[SessionService] thật (cần platform channel SQLite/
/// SharedPreferences không có sẵn trong môi trường `flutter test`).
class FakeAuthViewModel extends AuthViewModel {
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;

  /// Đặt false để tránh AuthScreen điều hướng sang MainShell sau khi login
  /// "thành công" (MainShell cần nhiều Provider khác không có trong test
  /// này) - bài test chỉ cần xác nhận đúng hàm được gọi với đúng tham số.
  bool loginResult = false;

  @override
  Future<bool> login({required String email, required String password}) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    notifyListeners();
    return loginResult;
  }
}

Widget _wrap(AuthViewModel viewModel) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: viewModel,
    child: const MaterialApp(home: AuthScreen()),
  );
}

void main() {
  group('AuthScreen', () {
    testWidgets('nhập email sai định dạng thì hiện lỗi và không gọi login', (tester) async {
      final fakeAuth = FakeAuthViewModel();
      await tester.pumpWidget(_wrap(fakeAuth));

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2)); // tab Log In mặc định: email + password

      await tester.enterText(fields.at(0), 'not-an-email');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(fakeAuth.loginCalled, isFalse);
    });

    testWidgets('nhập email hợp lệ + password đủ 6 ký tự thì gọi login với đúng tham số', (tester) async {
      final fakeAuth = FakeAuthViewModel();
      await tester.pumpWidget(_wrap(fakeAuth));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'student@scoops.com');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(fakeAuth.loginCalled, isTrue);
      expect(fakeAuth.lastEmail, 'student@scoops.com');
      expect(fakeAuth.lastPassword, '123456');
    });

    testWidgets('password dưới 6 ký tự thì hiện lỗi và không gọi login', (tester) async {
      final fakeAuth = FakeAuthViewModel();
      await tester.pumpWidget(_wrap(fakeAuth));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'student@scoops.com');
      await tester.enterText(fields.at(1), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(fakeAuth.loginCalled, isFalse);
    });
  });
}
