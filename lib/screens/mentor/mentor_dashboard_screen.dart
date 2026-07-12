import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mentor_dashboard_provider.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  State<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<MentorDashboardProvider>().loadForUser(auth.currentUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<MentorDashboardProvider>();
    final auth = context.watch<AuthProvider>();

    if (dashboard.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (dashboard.mentorProfile == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No mentor profile is linked to this account yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Dashboard'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: () => dashboard.loadForUser(auth.currentUser!.id),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back, ${dashboard.mentorProfile!.name.split(' ').first}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Upcoming sessions',
                    value: '${dashboard.upcomingCount}',
                    icon: Icons.event_available,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Completed',
                    value: '${dashboard.completedSessions}',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Total earnings (confirmed + completed)',
              value: '${dashboard.totalEarnings.toStringAsFixed(0)} VND',
              icon: Icons.payments_outlined,
              fullWidth: true,
              highlight: true,
            ),
            const SizedBox(height: 24),
            const Text('Your courses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (dashboard.courses.isEmpty)
              const Text('No courses created yet.', style: TextStyle(color: Colors.black54))
            else
              ...dashboard.courses.map((c) => Card(
                    child: ListTile(
                      title: Text(c.title),
                      subtitle: Text(c.status.name),
                      trailing: Text('${(c.price / 1000).toStringAsFixed(0)}k'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? AppTheme.primarySoft : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
