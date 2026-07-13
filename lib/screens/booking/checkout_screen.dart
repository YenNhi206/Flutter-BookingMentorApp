import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/mentor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

enum PaymentMethod { bankTransfer, eWallet }

class CheckoutScreen extends StatefulWidget {
  final Mentor mentor;
  final DateTime sessionDate;
  final String timeSlot;
  final int durationMinutes;
  final double price;
  final String notes;

  const CheckoutScreen({
    super.key,
    required this.mentor,
    required this.sessionDate,
    required this.timeSlot,
    required this.durationMinutes,
    required this.price,
    required this.notes,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.bankTransfer;
  bool _isProcessing = false;

  Future<void> _confirm() async {
    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    try {
      final booking = await bookingProvider.createBooking(
        studentId: auth.currentUser!.id,
        mentor: widget.mentor,
        sessionDate: widget.sessionDate,
        timeSlot: widget.timeSlot,
        durationMinutes: widget.durationMinutes,
        notes: widget.notes,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Booking request sent!'),
          content: Text(
            'Your session with ${widget.mentor.name} on '
            '${widget.sessionDate.day}/${widget.sessionDate.month}/${widget.sessionDate.year} '
            'at ${widget.timeSlot} is booked for ${booking.price.toStringAsFixed(0)} VND. '
            "It's now waiting for the mentor to confirm — you'll be notified once they do.",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('BookingConflictException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _summaryRow('Mentor', widget.mentor.name),
                  _summaryRow('Date', '${widget.sessionDate.day}/${widget.sessionDate.month}/${widget.sessionDate.year}'),
                  _summaryRow('Time', widget.timeSlot),
                  _summaryRow('Duration', '${widget.durationMinutes} minutes'),
                  const Divider(),
                  _summaryRow('Total', '${widget.price.toStringAsFixed(0)} VND', bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Payment method', style: TextStyle(fontWeight: FontWeight.bold)),
          RadioGroup<PaymentMethod>(
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v!),
            child: const Column(
              children: [
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.bankTransfer,
                  title: Text('Bank transfer'),
                ),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.eWallet,
                  title: Text('E-wallet (MoMo / ZaloPay)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is a simulated checkout for demo purposes — no real payment is processed.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLime,
              foregroundColor: AppTheme.ink,
            ),
            onPressed: _isProcessing ? null : _confirm,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.ink),
                  )
                : const Text('Confirm & pay'),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
