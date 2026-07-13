import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentor_link/core/token_storage.dart';
import 'package:mentor_link/data/repositories/auth_repository.dart';
import 'package:mentor_link/main.dart';
import 'package:mentor_link/providers/auth_provider.dart';

/// Avoids the real `flutter_secure_storage` platform channel, which has no
/// test harness and would otherwise hang `restoreSession()` indefinitely.
class _NoSessionTokenStorage extends TokenStorage {
  @override
  Future<String?> get accessToken => Future.value(null);
}

void main() {
  testWidgets('app boots to the login screen when unauthenticated', (tester) async {
    final authProvider = AuthProvider(
      repository: AuthRepository(tokenStorage: _NoSessionTokenStorage()),
    );
    await tester.pumpWidget(AppRoot(authProvider: authProvider));
    // AppRoot checks for a persisted session on startup (async) before
    // deciding to show the login screen - let that settle first.
    await tester.pumpAndSettle();

    expect(find.text('MentorLink'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });
}
