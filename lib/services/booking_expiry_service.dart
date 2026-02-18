import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> autoExpireBookings() async {
  final now = Timestamp.now();

  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: 'active')
      .where('endTime', isLessThanOrEqualTo: now)
      .get();

  for (final doc in snapshot.docs) {
    final booking = doc.data();
    final parkingId = booking['parkingId'];
    final slotId = booking['slotId'];

    // 1️⃣ Mark booking expired
    await doc.reference.update({'status': 'expired'});

    // 2️⃣ Free the slot
    await FirebaseFirestore.instance
        .collection('parkings')
        .doc(parkingId)
        .collection('slots')
        .doc(slotId)
        .update({'available': true, 'currentBookingId': FieldValue.delete()});
  }
}
