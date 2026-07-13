import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<BookingProvider>().loadForStudent(auth.currentUser!.id);
    });
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
    final auth = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final studentId = auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings'), automaticallyImplyLeading: false),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingProvider.myBookings.isEmpty
              ? const Center(
                  child: Text('No bookings yet — find a mentor to get started!', style: TextStyle(color: Colors.black54)),
                )
              : RefreshIndicator(
                  onRefresh: () => bookingProvider.loadForStudent(studentId),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: bookingProvider.myBookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookingProvider.myBookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(booking.mentorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${booking.sessionDate.day}/${booking.sessionDate.month}/${booking.sessionDate.year} · '
                            '${booking.timeSlot} · ${booking.durationMinutes} min · ${booking.price.toStringAsFixed(0)} VND',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text(
                                  booking.status.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                                backgroundColor: _statusColor(booking.status),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              if (booking.status == BookingStatus.confirmed)
                                TextButton(
                                  onPressed: () => bookingProvider.cancelBooking(booking.id, studentId),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
