// lib/pages/parking_slots_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:justparkit/pages/booking_summary_page.dart';

class ParkingSlotsPage extends StatefulWidget {
  final String parkingId;
  final String parkingName;

  const ParkingSlotsPage({
    super.key,
    required this.parkingId,
    required this.parkingName,
  });

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _getSlots() {
    return FirebaseFirestore.instance
        .collection('parkings')
        .doc(widget.parkingId)
        .collection('slots')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Parking Slot"),
        backgroundColor: const Color(0xFF5E35B1),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getSlots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final slots = snapshot.data!.docs;

          if (slots.isEmpty) {
            return const Center(child: Text("No slots available"));
          }

          return ListView.builder(
            itemCount: slots.length,
            itemBuilder: (_, i) {
              final slotDoc = slots[i];
              final slot = slotDoc.data();

              final bool available = slot['available'] == true;
              final int price = (slot['price'] ?? 0).toInt();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: ListTile(
                  title: Text("Slot ID: ${slotDoc.id}"),
                  subtitle: Text(
                    available ? "Available • ₹$price" : "Reserved",
                  ),
                  trailing: available
                      ? ElevatedButton(
                          child: const Text("Select"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingSummaryPage(
                                  parkingId: widget.parkingId,
                                  parkingName: widget.parkingName,
                                  slotId: slotDoc.id,
                                  price: price,
                                ),
                              ),
                            );
                          },
                        )
                      : const Text(
                          "FULL",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
