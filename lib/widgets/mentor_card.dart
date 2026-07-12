import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/mentor.dart';

class MentorCard extends StatelessWidget {
  final Mentor mentor;
  final VoidCallback onTap;

  const MentorCard({super.key, required this.mentor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(radius: 32, backgroundImage: NetworkImage(mentor.avatarUrl)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(mentor.title, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: mentor.expertise
                          .take(2)
                          .map((e) => Chip(
                                label: Text(e, style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(mentor.rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(mentor.hourlyRate / 1000).toStringAsFixed(0)}k/hr',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
