import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FullScreenMapPage extends StatelessWidget {
  final List<Marker> markers;
  final LatLng center;
  final double zoom;

  const FullScreenMapPage({
    super.key,
    required this.markers,
    required this.center,
    this.zoom = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map — Full Screen'),
        backgroundColor: const Color(0xFF5E35B1),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center, // ✅ CORRECT
          initialZoom: zoom, // ✅ CORRECT
          minZoom: 3,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.justparkit',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
