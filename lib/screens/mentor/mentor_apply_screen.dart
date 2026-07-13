import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../providers/auth_provider.dart';

/// Lets a student self-apply to become a mentor (`POST /mentors/apply`).
/// The application then waits for an admin to approve it - the account
/// stays a student until then, matching the app's existing pending-mentor
/// admin-approval workflow.
class MentorApplyScreen extends StatefulWidget {
  const MentorApplyScreen({super.key});

  @override
  State<MentorApplyScreen> createState() => _MentorApplyScreenState();
}

class _MentorApplyScreenState extends State<MentorApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _rateController = TextEditingController();
  final _repository = MentorRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bioController.dispose();
    _expertiseController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _repository.apply(
        title: _titleController.text.trim(),
        bio: _bioController.text.trim(),
        expertise: _expertiseController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        hourlyRate: double.tryParse(_rateController.text.trim()) ?? 0,
      );
      // Pick up an immediate role change, if the backend ever grants one on apply.
      if (mounted) await context.read<AuthProvider>().restoreSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted. Waiting for admin approval.')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a mentor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us about yourself. An admin will review your application before you can accept bookings.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Senior Flutter Engineer @ Grab'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bio is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expertiseController,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma-separated)',
                  hintText: 'Flutter, Dart, Mobile Architecture',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'At least one skill is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hourly rate (VND)'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter a valid rate';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
