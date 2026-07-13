import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/admin_provider.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

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
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('All bookings'), automaticallyImplyLeading: false),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: admin.bookings.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final booking = admin.bookings[index];
                return ListTile(
                  title: Text(booking.mentorName),
                  subtitle: Text(
                    '${booking.sessionDate.day}/${booking.sessionDate.month}/${booking.sessionDate.year} · '
                    '${booking.timeSlot} · ${booking.price.toStringAsFixed(0)} VND',
                  ),
                  trailing: Chip(
                    label: Text(booking.status.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: _statusColor(booking.status),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
    );
  }
}
