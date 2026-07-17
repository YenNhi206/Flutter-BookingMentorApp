import 'package:flutter_test/flutter_test.dart';
import 'package:scoops/core/constants.dart';
import 'package:scoops/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (tester) async {
    await tester.pumpWidget(const ScoopsApp());

    // Chỉ pump 1 frame đầu tiên - không để animation của Splash chạy hết
    // (tránh kích hoạt điều hướng sang Onboarding/MainShell, vốn cần nhiều
    // Provider khác không liên quan tới bài test khởi động app này).
    expect(find.text(AppConstants.appTagline), findsOneWidget);
  });
}
