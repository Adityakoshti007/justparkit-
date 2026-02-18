// lib/widgets/parking_map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ParkingMapWidget extends StatefulWidget {
  final List<Marker> markers;
  final LatLng center;
  final double zoom;
  final MapController mapController;
  final VoidCallback? onMapReady;
  final void Function(LatLng)? onMapTap;

  // ✅ ROUTE POINTS COMING FROM HOME PAGE
  final List<LatLng> polylines;

  const ParkingMapWidget({
    super.key,
    required this.markers,
    required this.center,
    required this.mapController,
    this.zoom = 12.0,
    this.onMapTap,
    this.onMapReady,
    required this.polylines,
  });

  @override
  State<ParkingMapWidget> createState() => _ParkingMapWidgetState();
}

class _ParkingMapWidgetState extends State<ParkingMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          initialCenter: widget.center,
          initialZoom: widget.zoom,
          onMapReady: widget.onMapReady,
          minZoom: 3,
          maxZoom: 18,
          onTap: (tapPosition, latLng) {
            widget.onMapTap?.call(latLng);
          },
        ),
        children: [
          // 🗺️ MAP TILES
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.justparkit',
          ),

          // 🧭 ROUTE POLYLINE (SAFE)
          if (widget.polylines.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.polylines,
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              ],
            ),

          // 📍 MARKERS
          MarkerLayer(markers: widget.markers),
        ],
      ),
    );
  }
}
