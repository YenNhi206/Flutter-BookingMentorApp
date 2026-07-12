import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'mentor_bookings_screen.dart';
import 'mentor_courses_screen.dart';
import 'mentor_dashboard_screen.dart';

class MentorShell extends StatefulWidget {
  const MentorShell({super.key});

  @override
  State<MentorShell> createState() => _MentorShellState();
}

class _MentorShellState extends State<MentorShell> {
  int _index = 0;

  static const _screens = [
    MentorDashboardScreen(),
    MentorBookingsScreen(),
    MentorCoursesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<NotificationProvider>().loadForUser(auth.currentUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Bookings'),
          const NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Courses'),
          NavigationDestination(
            icon: Badge(
              label: Text('$unread'),
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
