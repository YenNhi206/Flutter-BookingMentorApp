import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/mentor.dart';
import 'checkout_screen.dart';

const _availableSlots = ['09:00', '10:30', '13:00', '15:00', '16:30', '19:00'];
const _durations = [30, 60, 90];

class BookingScreen extends StatefulWidget {
  final Mentor mentor;
  const BookingScreen({super.key, required this.mentor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = _availableSlots.first;
  int _selectedDuration = _durations[1];
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _price => widget.mentor.hourlyRate * _selectedDuration / 60;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(widget.mentor.avatarUrl)),
              title: Text(widget.mentor.name),
              subtitle: Text(widget.mentor.title),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Session date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 20),
          const Text('Time slot', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots
                .map((slot) => ChoiceChip(
                      label: Text(slot),
                      selected: _selectedSlot == slot,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _durations
                .map((d) => ChoiceChip(
                      label: Text('$d min'),
                      selected: _selectedDuration == d,
                      onSelected: (_) => setState(() => _selectedDuration = d),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Notes for mentor (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'What would you like to focus on?'),
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(
                  mentor: widget.mentor,
                  sessionDate: _selectedDate,
                  timeSlot: _selectedSlot,
                  durationMinutes: _selectedDuration,
                  price: _price,
                  notes: _notesController.text.trim(),
                ),
              ),
            ),
            child: Text('Continue — ${_price.toStringAsFixed(0)} VND'),
          ),
        ),
      ),
    );
  }
}
