import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mentor_dashboard_provider.dart';

class MentorBookingsScreen extends StatefulWidget {
  const MentorBookingsScreen({super.key});

  @override
  State<MentorBookingsScreen> createState() => _MentorBookingsScreenState();
}

class _MentorBookingsScreenState extends State<MentorBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<MentorDashboardProvider>().loadForUser(auth.currentUser!.id);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return Colors.green;
      case BookingStatus.pending:
      case BookingStatus.rescheduled:
        return Colors.orange;
      case BookingStatus.completed:
        return Colors.blueGrey;
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<MentorDashboardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings'), automaticallyImplyLeading: false),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboard.bookings.isEmpty
              ? const Center(child: Text('No bookings yet', style: TextStyle(color: Colors.black54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dashboard.bookings.length,
                  itemBuilder: (context, index) {
                    final booking = dashboard.bookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${booking.sessionDate.day}/${booking.sessionDate.month}/${booking.sessionDate.year} · ${booking.timeSlot}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Chip(
                                  label: Text(booking.status.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  backgroundColor: _statusColor(booking.status),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${booking.durationMinutes} min · ${booking.price.toStringAsFixed(0)} VND'),
                            if (booking.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Note: ${booking.notes}', style: const TextStyle(color: Colors.black54)),
                            ],
                            if (booking.status == BookingStatus.pending) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _runAction(() => dashboard.cancelBooking(booking.id)),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _runAction(() => dashboard.confirmBooking(booking.id)),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            ],
                            if (booking.status == BookingStatus.confirmed) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _runAction(() => dashboard.cancelBooking(booking.id)),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _runAction(() => dashboard.markCompleted(booking.id)),
                                    child: const Text('Mark completed'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
