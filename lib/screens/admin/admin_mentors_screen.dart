import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mentor.dart';
import '../../providers/admin_provider.dart';

class AdminMentorsScreen extends StatelessWidget {
  const AdminMentorsScreen({super.key});

  Color _statusColor(MentorStatus status) {
    switch (status) {
      case MentorStatus.approved:
        return Colors.green;
      case MentorStatus.pending:
        return Colors.orange;
      case MentorStatus.rejected:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mentors'), automaticallyImplyLeading: false),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: admin.mentors.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final mentor = admin.mentors[index];
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(mentor.avatarUrl)),
                  title: Text(mentor.name),
                  subtitle: Text(mentor.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(mentor.status.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: _statusColor(mentor.status),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      if (mentor.status == MentorStatus.pending) ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => admin.approveMentor(mentor.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          onPressed: () => admin.rejectMentor(mentor.id),
                        ),
                      ] else
                        Switch(
                          value: mentor.isActive,
                          onChanged: (value) => admin.setMentorActive(mentor.id, value),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
