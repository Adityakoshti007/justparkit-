import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ParkingSearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Convert city / area → LatLng
  Future<LatLng?> getLatLngFromSearch(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return null;

      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Distance in KM
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// 🔍 MAIN SEARCH METHOD
  Future<List<Map<String, dynamic>>> getNearbyParkings(
    String searchText,
  ) async {
    final center = await getLatLngFromSearch(searchText);
    if (center == null) return [];

    final snap = await _db.collection('parkings').get();
    final List<Map<String, dynamic>> results = [];

    for (final doc in snap.docs) {
      final data = doc.data();

      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      final distance = _distanceKm(center.latitude, center.longitude, lat, lng);

      /// 🔥 50 KM radius (Mumbai ↔ Bhiwandi works)
      if (distance <= 50) {
        results.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Parking',
          'image': data['imageUrl'] ?? 'https://via.placeholder.com/300',
          'price': data['price'] ?? 0,
          'rating': data['rating'] ?? 0.0,
          'latlng': LatLng(lat, lng),
        });
      }
    }

    return results;
  }
}
