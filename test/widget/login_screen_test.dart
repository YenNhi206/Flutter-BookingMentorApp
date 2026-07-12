import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mentor_link/providers/auth_provider.dart';
import 'package:mentor_link/screens/auth/login_screen.dart';

void main() {
  Widget wrapWithProviders(Widget child) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows validation errors when submitting empty fields', (tester) async {
    await tester.pumpWidget(wrapWithProviders(const LoginScreen()));

    await tester.enterText(find.byKey(const Key('emailField')), '');
    await tester.enterText(find.byKey(const Key('passwordField')), '');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('shows an email format error for an invalid address', (tester) async {
    await tester.pumpWidget(wrapWithProviders(const LoginScreen()));

    await tester.enterText(find.byKey(const Key('emailField')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
