import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getParkings() {
    return _db.collection('parkings').snapshots();
  }

  Stream<QuerySnapshot> getSlots(String parkingId) {
    return _db
        .collection('parkings')
        .doc(parkingId)
        .collection('slots')
        .snapshots();
  }

  Future<void> bookSlot(String parkingId, String slotId, String userId) async {
    // mark slot unavailable
    await _db
        .collection('parkings')
        .doc(parkingId)
        .collection('slots')
        .doc(slotId)
        .update({'available': false});

    // create booking
    await _db.collection('bookings').add({
      'userId': userId,
      'parkingId': parkingId,
      'slotId': slotId,
      'time': Timestamp.now(),
    });
  }
}
