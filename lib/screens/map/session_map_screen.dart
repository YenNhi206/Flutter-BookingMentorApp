import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../models/mentor.dart';

class SessionMapScreen extends StatelessWidget {
  final Mentor mentor;
  const SessionMapScreen({super.key, required this.mentor});

  @override
  Widget build(BuildContext context) {
    final location = LatLng(mentor.latitude, mentor.longitude);
    return Scaffold(
      appBar: AppBar(title: const Text('Session location')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: location, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.prm393.mentorlink',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on, color: AppTheme.primary, size: 44),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.place_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text('${mentor.name} usually meets at ${mentor.sessionAddress}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
