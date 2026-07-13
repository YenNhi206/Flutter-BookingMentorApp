import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
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
  await LocalNotificationService.instance.init();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  /// Overridable for tests, so they don't depend on the real
  /// `flutter_secure_storage` platform channel being available.
  final AuthProvider? authProvider;

  const AppRoot({super.key, this.authProvider});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider ?? AuthProvider();
    _authProvider.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
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
