import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'models/user_profile.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/mentor/mentor_shell.dart';

class MentorLinkApp extends StatelessWidget {
  const MentorLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MentorLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const LoginScreen();
          switch (auth.currentUser!.role) {
            case UserRole.mentor:
              return const MentorShell();
            case UserRole.admin:
              return const AdminShell();
            case UserRole.student:
              return const MainShell();
          }
        },
      ),
    );
  }
}
