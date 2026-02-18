import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:justparkit/admin/admin_bookings_page.dart';
import 'package:justparkit/services/booking_expiry_service.dart';

import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:justparkit/admin/add_parking_page.dart';
import 'package:justparkit/pages/parking_slots_page.dart';
import 'package:justparkit/pages/profile_page.dart';
import 'package:justparkit/pages/my_bookings_page.dart';

import '../widgets/parking_map_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> get _nearbyParkings {
    if (_userLocation == null) return [];

    final sorted = List<Map<String, dynamic>>.from(_allParkings);

    sorted.sort((a, b) {
      final d1 = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        a['latlng'].latitude,
        a['latlng'].longitude,
      );

      final d2 = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        b['latlng'].latitude,
        b['latlng'].longitude,
      );

      return d1.compareTo(d2);
    });

    return sorted.take(5).toList(); // show top 5 nearby
  }

  //  ========== Navigation Function =============

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _navigateToParking(LatLng destination) async {
    if (_userLocation == null) {
      _toast('User location not available');
      return;
    }
    debugPrint('NAV TO: $destination');

    final origin = '${_userLocation!.latitude},${_userLocation!.longitude}';
    final dest = '${destination.latitude},${destination.longitude}';

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Could not open Google Maps');
    }
  }

  // ================= ADMIN =================
  bool _isAdmin = false;

  // ================= MAP =================
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(19.0760, 72.8777);
  bool _hasCenteredMap = false;

  // ================= SEARCH =================
  final TextEditingController _searchController = TextEditingController();

  // ================= LIVE LOCATION =================
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;

  // ================= PARKINGS =================
  List<Map<String, dynamic>> _allParkings = [];
  List<Map<String, dynamic>> _searchResults = [];

  // =============== ROUTE STATE ===============
  List<LatLng> _routePoints = [];
  bool _isNavigating = false;

  // final List<Map<String, String>> nearbyParkings = [
  //   {'name': 'BMC Parking', 'image': 'https://i.imgur.com/8Km9tLL.jpg'},
  //   {'name': 'Public Parking', 'image': 'https://i.imgur.com/QwhZRyL.png'},
  //   {'name': 'AAI Parking', 'image': 'https://i.imgur.com/7vQD0fP.jpg'},
  // ];

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    autoExpireBookings();
    _loadUserRole();
    _loadAllParkings();
    _startLiveLocation();
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ================= USER ROLE =================
  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    setState(() {
      _isAdmin = doc.data()?['role'] == 'admin';
    });
  }

  // ================= LIVE LOCATION =================
  Future<void> _startLiveLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          final latLng = LatLng(position.latitude, position.longitude);

          setState(() {
            _userLocation = latLng;
          });

          // 🔥 CENTER MAP ONLY ONCE (USER LOCATION)
          if (!_hasCenteredMap) {
            _mapController.move(latLng, 14);
            _hasCenteredMap = true;
          }
        });
  }

  // ================= LOAD PARKINGS =================
  void _loadAllParkings() {
    FirebaseFirestore.instance.collection('parkings').snapshots().listen((
      snap,
    ) {
      final List<Map<String, dynamic>> list = [];

      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['latitude'] == null || d['longitude'] == null) continue;

        list.add({
          'id': doc.id,
          'name': d['name'],
          'price': d['price'],
          'rating': d['rating'],
          'latlng': LatLng(
            (d['latitude'] as num).toDouble(),
            (d['longitude'] as num).toDouble(),
          ),
        });
      }

      setState(() {
        _allParkings = list;
      });
    });
  }

  // ================= SEARCH =================
  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) return;

    final locations = await locationFromAddress(query);
    if (locations.isEmpty) return;

    final lat = locations.first.latitude;
    final lng = locations.first.longitude;

    setState(() {
      _mapCenter = LatLng(lat, lng);
      _searchResults = _allParkings;
    });

    _mapController.move(_mapCenter, 13);
  }

  // ================= MARKERS =================
  List<Marker> get _markers {
    final List<Marker> markers = [];

    // ============== ROUTE FETCH FUNCTION =================
    Future<void> _drawRouteToParking(LatLng destination) async {
      if (_userLocation == null) {
        _toast('User location not available');
        return;
      }

      final start = _userLocation!;
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      try {
        final response = await http.get(Uri.parse(url));
        final data = jsonDecode(response.body);

        final coords = data['routes'][0]['geometry']['coordinates'];

        final List<LatLng> points = coords
            .map<LatLng>((c) => LatLng(c[1], c[0]))
            .toList();

        setState(() {
          _routePoints = points;
          _isNavigating = true;
        });

        // Zoom map to route start
        _mapController.move(start, 14);
      } catch (e) {
        debugPrint('ROUTE ERROR: $e');
        _toast('Failed to load route');
      }
    }

    // 🔵 USER LOCATION
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 30,
          height: 30,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      );
    }

    // 🔴 PARKINGS
    final data = _searchResults.isNotEmpty ? _searchResults : _allParkings;

    for (final p in data) {
      markers.add(
        Marker(
          point: p['latlng'],
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showParkingSheet(p),
            child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
          ),
        ),
      );
    }

    return markers;
  }

  // 🧭 NAVIGATION TO PARKING (ADD HERE)
  Future<void> navigateToParking(LatLng destination) async {
    if (_userLocation == null) {
      _toast('User location not available');
      return;
    }

    final origin = '${_userLocation!.latitude},${_userLocation!.longitude}';
    final dest = '${destination.latitude},${destination.longitude}';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$dest'
      '&travelmode=driving',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _toast('Google Maps not found');
      debugPrint('NAV ERROR: $e');
    }
  }

  // =============== drawrouteparking ================
  Future<void> _drawRouteToParking(LatLng destination) async {
    if (_userLocation == null) {
      _toast('User location not available');
      return;
    }

    // Example using OSRM (OpenStreetMap routing)
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation!.longitude},${_userLocation!.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      _toast('Route not found');
      return;
    }

    final data = jsonDecode(response.body);
    final coords = data['routes'][0]['geometry']['coordinates'];

    setState(() {
      _routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    });
  }

  // ================= BOTTOM SHEET =================
  void _showParkingSheet(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('₹${p['price']} / hour'),
            Text('⭐ ${p['rating']}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParkingSlotsPage(
                            parkingId: p['id'],
                            parkingName: p['name'],
                          ),
                        ),
                      );
                    },
                    child: const Text('Book'),
                  ),
                ),
                const SizedBox(width: 12),

                // 🧭 NAVIGATE BUTTON
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _drawRouteToParking(p['latlng'] as LatLng);
                  },
                  child: const Text('Navigate'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // 🔥 OPTION 1 — CLEAR ROUTE WHEN SHEET CLOSES
      setState(() {
        _routePoints.clear();
      });
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF4B4BE0),
        title: const Text(
          'JustParkIt',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (_isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.admin_panel_settings),
              onSelected: (value) {
                if (value == 'parking') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddParkingPage()),
                  );
                } else if (value == 'bookings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminBookingsPage(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'parking', child: Text('Manage Parking')),
                PopupMenuItem(value: 'bookings', child: Text('User Bookings')),
              ],
            ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search Parking.....',
                    border: InputBorder.none,
                  ),
                  onSubmitted: _onSearch,
                ),
              ),
            ),

            // NEARBY PARKING
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Nearby Parking Spot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _nearbyParkings.length,
                itemBuilder: (_, i) {
                  final p = _nearbyParkings[i];

                  return GestureDetector(
                    onTap: () {
                      _mapController.move(p['latlng'], 14);
                      _showParkingSheet(p);
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.local_parking,
                            size: 32,
                            color: Color(0xFF4B4BE0),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${p['price']} / hr',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🗺 MAP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ParkingMapWidget(
                    mapController: _mapController,
                    center: _mapCenter,
                    zoom: 11,
                    markers: _markers,
                    polylines: _routePoints,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF4B4BE0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.home, 'Home'),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyBookingsPage()),
              ),
              child: _navItem(Icons.bookmark, 'Booking'),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              ),
              child: _navItem(Icons.person, 'User'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
