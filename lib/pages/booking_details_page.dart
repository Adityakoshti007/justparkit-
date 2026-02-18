// lib/pages/booking_details_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'full_screen_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _fmt = DateFormat('yyyy-MM-dd HH:mm');
  bool _isCancelling = false;
  DocumentSnapshot<Map<String, dynamic>>? _bookingSnapshot;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final doc = await _db.collection('bookings').doc(widget.bookingId).get();
      if (!mounted) return;
      setState(() {
        _bookingSnapshot = doc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    final bookingRef = _db.collection('bookings').doc(widget.bookingId);

    setState(() => _isCancelling = true);

    try {
      await _db.runTransaction((tx) async {
        // 1️⃣ READ booking FIRST
        final bookingSnap = await tx.get(bookingRef);
        if (!bookingSnap.exists) {
          throw Exception('Booking not found');
        }

        final bookingData = bookingSnap.data()!;
        final status = bookingData['status'];

        if (status != 'active') {
          throw Exception('Only active bookings can be cancelled');
        }

        final parkingId = bookingData['parkingId'];
        final slotId = bookingData['slotId'];

        DocumentSnapshot<Map<String, dynamic>>? slotSnap;
        DocumentReference<Map<String, dynamic>>? slotRef;

        // 2️⃣ READ slot BEFORE any write
        if (parkingId != null && slotId != null) {
          slotRef = _db
              .collection('parkings')
              .doc(parkingId)
              .collection('slots')
              .doc(slotId);

          slotSnap = await tx.get(slotRef);
        }

        // 3️⃣ NOW DO ALL WRITES
        tx.update(bookingRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        if (slotSnap != null && slotSnap.exists) {
          final slotData = slotSnap.data()!;
          final currentBookingId = slotData['currentBookingId'];

          if (currentBookingId == widget.bookingId) {
            tx.update(slotRef!, {
              'available': true,
              'currentBookingId': null,
              'bookedUntil': null,
            });
          }
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );

      await _loadBooking();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // This method fetches parking doc, extracts coordinates and opens full screen map
  Future<void> _showOnMap() async {
    if (_bookingSnapshot == null) return;

    final data = _bookingSnapshot!.data()!;
    final parkingId = data['parkingId'] as String?;

    if (parkingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No parkingId found')));
      return;
    }

    try {
      final p = await FirebaseFirestore.instance
          .collection('parkings')
          .doc(parkingId)
          .get();

      if (!p.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parking not found')));
        return;
      }

      final pd = p.data()!;
      if (pd['latitude'] == null || pd['longitude'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parking has no coordinates')),
        );
        return;
      }

      final LatLng center = LatLng(
        (pd['latitude'] as num).toDouble(),
        (pd['longitude'] as num).toDouble(),
      );

      final marker = Marker(
        point: center,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FullScreenMapPage(markers: [marker], center: center, zoom: 15.0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load parking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color(0xFF5E35B1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _bookingSnapshot == null || !_bookingSnapshot!.exists
          ? const Center(child: Text('Booking not found'))
          : _buildDetails(context),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final data = _bookingSnapshot!.data()!;
    final parkingId = data['parkingId'] as String? ?? '—';
    final slotId = data['slotId'] as String? ?? '—';
    final price = (data['price'] ?? 0).toString();
    final status = (data['status'] ?? 'unknown') as String;
    final created = (data['createdAt'] as Timestamp?)?.toDate();
    final start = (data['start'] as Timestamp?)?.toDate();
    final end = (data['end'] as Timestamp?)?.toDate();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parking: $parkingId',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Slot: $slotId'),
          const SizedBox(height: 8),
          if (start != null) Text('From: ${_fmt.format(start)}'),
          if (end != null) Text('To:   ${_fmt.format(end)}'),
          const SizedBox(height: 8),
          Text(
            'Price: ₹$price',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (created != null)
            Text(
              'Booked: ${_fmt.format(created)}',
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(status.toUpperCase()),
                backgroundColor: status == 'active'
                    ? Colors.green[50]
                    : Colors.red[50],
                labelStyle: TextStyle(
                  color: status == 'active'
                      ? Colors.green[800]
                      : Colors.red[800],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showOnMap,
                icon: const Icon(Icons.map),
                label: const Text('Show on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: Container()),
          if (status == 'active')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCancelling
                    ? null
                    : () async {
                        final ok =
                            await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Cancel booking?'),
                                content: const Text(
                                  'Are you sure you want to cancel this booking?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (ok) await _cancelBooking();
                      },
                icon: const Icon(Icons.cancel),
                label: _isCancelling
                    ? const Text('Cancelling...')
                    : const Text('Cancel Booking'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
        ],
      ),
    );
  }
}
