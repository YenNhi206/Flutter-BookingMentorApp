import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mentor_provider.dart';
import '../../widgets/mentor_card.dart';
import 'mentor_detail_screen.dart';

class MentorListScreen extends StatefulWidget {
  const MentorListScreen({super.key});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MentorProvider>().loadMentors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mentorProvider = context.watch<MentorProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a mentor'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, skill, or role',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => context.read<MentorProvider>().search(value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: mentorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : mentorProvider.mentors.isEmpty
                    ? const Center(child: Text('No mentors found'))
                    : RefreshIndicator(
                        onRefresh: mentorProvider.loadMentors,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: mentorProvider.mentors.length,
                          itemBuilder: (context, index) {
                            final mentor = mentorProvider.mentors[index];
                            return MentorCard(
                              mentor: mentor,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => MentorDetailScreen(mentorId: mentor.id)),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
