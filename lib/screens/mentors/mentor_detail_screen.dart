import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/mentor.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mentor_provider.dart';
import '../booking/booking_screen.dart';
import '../chat/chat_screen.dart';
import '../map/session_map_screen.dart';

class MentorDetailScreen extends StatefulWidget {
  final String mentorId;
  const MentorDetailScreen({super.key, required this.mentorId});

  @override
  State<MentorDetailScreen> createState() => _MentorDetailScreenState();
}

class _MentorDetailScreenState extends State<MentorDetailScreen> {
  Mentor? _mentor;
  List<Review> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<MentorProvider>();
    final mentor = await provider.getById(widget.mentorId);
    final reviews = await provider.getReviews(widget.mentorId);
    if (!mounted) return;
    setState(() {
      _mentor = mentor;
      _reviews = reviews;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mentor = _mentor;
    if (mentor == null) {
      return const Scaffold(body: Center(child: Text('Mentor not found')));
    }
    final auth = context.watch<AuthProvider>();
    final studentId = auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: Text(mentor.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 40, backgroundImage: NetworkImage(mentor.avatarUrl)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentor.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(' ${mentor.rating} (${mentor.reviewCount} reviews)'),
                      ],
                    ),
                    Text('${(mentor.hourlyRate / 1000).toStringAsFixed(0)}k VND / hour',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: mentor.expertise.map((e) => Chip(label: Text(e))).toList(),
          ),
          const SizedBox(height: 16),
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(mentor.bio, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(mentor.sessionAddress),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SessionMapScreen(mentor: mentor)),
            ),
          ),
          const Divider(),
          const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_reviews.isEmpty)
            const Text('No reviews yet. Be the first to book and review!', style: TextStyle(color: Colors.black54))
          else
            ..._reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(r.comment, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        mentorId: mentor.id,
                        mentorName: mentor.name,
                        studentId: studentId,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Book session'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookingScreen(mentor: mentor)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
