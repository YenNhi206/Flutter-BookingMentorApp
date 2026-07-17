import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../models/store.dart';
import '../../viewmodels/food_vm.dart';

/// Bản đồ các cửa hàng Scoops (OpenStreetMap qua `flutter_map`, không cần
/// API key). Tap marker mở bottom sheet thông tin cửa hàng.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _hcmcCenter = LatLng(10.7930, 106.7010);

  @override
  Widget build(BuildContext context) {
    final stores = context.watch<FoodViewModel>().stores;

    return Scaffold(
      appBar: AppBar(title: const Text('Store Locations')),
      body: FlutterMap(
        options: const MapOptions(initialCenter: _hcmcCenter, initialZoom: 12),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.scoops.app',
          ),
          MarkerLayer(
            markers: stores
                .map((store) => Marker(
                      point: LatLng(store.lat, store.lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showStoreSheet(context, store),
                        child: Container(
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.icecream_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showStoreSheet(BuildContext context, Store store) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(store.address, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(store.rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Order from here'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
