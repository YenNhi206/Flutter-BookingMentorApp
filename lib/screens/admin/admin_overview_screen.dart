import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../providers/admin_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/course.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  List<Course> _pendingCourses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminProvider>().loadAll();
      final pending = await context.read<CourseProvider>().getPendingReview();
      if (mounted) setState(() => _pendingCourses = pending);
    });
  }

  Future<void> _refresh() async {
    await context.read<AdminProvider>().loadAll();
    final pending = await context.read<CourseProvider>().getPendingReview();
    if (mounted) setState(() => _pendingCourses = pending);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Overview'), automaticallyImplyLeading: false),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatTile(label: 'Users', value: '${admin.users.length}', icon: Icons.people_outline),
                      _StatTile(label: 'Mentors', value: '${admin.mentors.length}', icon: Icons.school_outlined),
                      _StatTile(label: 'Bookings', value: '${admin.bookings.length}', icon: Icons.event_note_outlined),
                      _StatTile(
                        label: 'Revenue (VND)',
                        value: admin.totalRevenue.toString(),
                        icon: Icons.payments_outlined,
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Bookings by status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BookingStatus.values
                        .map((s) => Chip(label: Text('${s.name}: ${admin.bookingsByStatus[s] ?? 0}')))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Pending mentor approvals (${admin.pendingMentors.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (admin.pendingMentors.isEmpty)
                    const Text('Nothing to review.', style: TextStyle(color: Colors.black54))
                  else
                    ...admin.pendingMentors.map((m) => Card(
                          child: ListTile(
                            title: Text(m.name),
                            subtitle: Text(m.title),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => admin.approveMentor(m.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                  onPressed: () => admin.rejectMentor(m.id),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),
                  Text('Pending course approvals (${_pendingCourses.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_pendingCourses.isEmpty)
                    const Text('Nothing to review.', style: TextStyle(color: Colors.black54))
                  else
                    ..._pendingCourses.map((c) => Card(
                          child: ListTile(
                            title: Text(c.title),
                            subtitle: Text('by ${c.mentorName}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () async {
                                    await context.read<CourseProvider>().approve(c.id);
                                    _refresh();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                  onPressed: () async {
                                    await context.read<CourseProvider>().reject(c.id);
                                    _refresh();
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatTile({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? AppTheme.primarySoft : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
