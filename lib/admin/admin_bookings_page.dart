import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBookingsPage extends StatelessWidget {
  const AdminBookingsPage({super.key});

  String _format(Timestamp ts) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All User Bookings'),
        backgroundColor: const Color(0xFF4B4BE0),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings yet'));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (_, i) {
              final data = bookings[i].data();

              // 🛑 SAFE TIMESTAMP HANDLING
              final Timestamp? startTs = data['startTime'] as Timestamp?;
              final Timestamp? endTs = data['endTime'] as Timestamp?;

              final String startText = startTs != null
                  ? _format(startTs)
                  : 'Not available';

              final String endText = endTs != null
                  ? _format(endTs)
                  : 'Not available';

              final String userName = data['userName'] ?? 'User';
              final String email = data['email'] ?? 'No email';
              final String slot = data['slotId'] ?? '-';
              final String parking = data['parkingName'] ?? 'Parking';
              final int price = data['price'] ?? 0;
              final String status = data['status'] ?? 'unknown';

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parking,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('User: $userName'),
                      Text('Email: $email'),
                      Text('Slot: $slot'),
                      const SizedBox(height: 6),
                      Text('From: $startText'),
                      Text('To: $endText'),
                      const SizedBox(height: 6),
                      Text(
                        '₹$price',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: status == 'active'
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
