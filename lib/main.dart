import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/seed/seed_data.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/course_provider.dart';
import 'providers/cv_analysis_provider.dart';
import 'providers/mentor_dashboard_provider.dart';
import 'providers/mentor_provider.dart';
import 'providers/notification_provider.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SeedData.seedIfEmpty();
  await LocalNotificationService.instance.init();
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MentorProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MentorDashboardProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => CvAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MentorLinkApp(),
    );
  }
}
