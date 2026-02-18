import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'parking_slots_page.dart';

class ParkingDetailsPage extends StatelessWidget {
  final String parkingId;

  const ParkingDetailsPage({super.key, required this.parkingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Details'),
        backgroundColor: const Color(0xFF4B4BE0),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('parkings')
            .doc(parkingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Parking not found'));
          }

          final data = snapshot.data!.data()!;

          final image = data['imageUrl'] ?? 'https://via.placeholder.com/300';
          final name = data['name'] ?? 'Parking';
          final rating = data['rating'] ?? 0;
          final price = data['price'] ?? 0;
          final subtitle = data['subtitle'] ?? '';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  image,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$rating'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹$price / hour',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(subtitle),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ParkingSlotsPage(
                                  parkingId: parkingId,
                                  parkingName: '',
                                ),
                              ),
                            );
                          },
                          child: const Text('Book Parking'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
