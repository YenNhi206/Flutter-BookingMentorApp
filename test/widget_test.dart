import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentor_link/main.dart';

void main() {
  testWidgets('app boots to the login screen when unauthenticated', (tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pump();

    expect(find.text('MentorLink'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });
}
