import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:justparkit/pages/booking_details_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _fmt = DateFormat('dd MMM yyyy, hh:mm a');

  // 🔥 AUTO EXPIRE BOOKINGS
  @override
  void initState() {
    super.initState();
    autoExpireBookings();
  }

  Future<void> autoExpireBookings() async {
    final now = Timestamp.now();

    final snapshot = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'active')
        .where('endTime', isLessThanOrEqualTo: now)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final parkingId = data['parkingId'];
      final slotId = data['slotId'];

      // expire booking
      await doc.reference.update({'status': 'expired'});

      // free slot
      await _db
          .collection('parkings')
          .doc(parkingId)
          .collection('slots')
          .doc(slotId)
          .update({'available': true, 'currentBookingId': null});
    }
  }

  // 🔄 USER BOOKINGS STREAM
  Stream<QuerySnapshot<Map<String, dynamic>>> _userBookingsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ❌ CANCEL BOOKING
  Future<void> _cancelBooking(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    final parkingId = data['parkingId'];
    final slotId = data['slotId'];

    await _db.runTransaction((tx) async {
      tx.update(_db.collection('bookings').doc(bookingId), {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      tx.update(
        _db
            .collection('parkings')
            .doc(parkingId)
            .collection('slots')
            .doc(slotId),
        {'available': true, 'currentBookingId': null},
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    }
  }

  // 🧱 SINGLE BOOKING TILE
  Widget _bookingTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = data['status'] ?? 'unknown';

    final start = (data['startTime'] as Timestamp?)?.toDate();
    final end = (data['endTime'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(
          '${data['parkingName']}  •  Slot ${data['slotId']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (start != null) Text('From: ${_fmt.format(start)}'),
            if (end != null) Text('To: ${_fmt.format(end)}'),
            Text('Price: ₹${data['price']}'),

            const SizedBox(height: 4),

            // ✅ STATUS DISPLAY (CORRECT PLACE)
            Text(
              'Status: ${status.toUpperCase()}',
              style: TextStyle(
                color: status == 'active'
                    ? Colors.green
                    : status == 'expired'
                    ? Colors.grey
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: status == 'active'
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _cancelBooking(context, doc.id, data),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailsPage(bookingId: doc.id),
            ),
          );
        },
      ),
    );
  }

  // 🏁 BUILD
  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _userBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No bookings yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) => _bookingTile(context, docs[i]),
          );
        },
      ),
    );
  }
}
