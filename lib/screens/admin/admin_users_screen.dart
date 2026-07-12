import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Users'), automaticallyImplyLeading: false),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: admin.users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = admin.users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('${user.email} · ${user.role.name}'),
                  trailing: Switch(
                    value: user.isActive,
                    onChanged: (value) => admin.setUserActive(user.id, value),
                  ),
                );
              },
            ),
    );
  }
}
