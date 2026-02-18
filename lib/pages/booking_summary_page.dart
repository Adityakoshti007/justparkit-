import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:justparkit/services/email_service.dart';
import 'dummy_payment_page.dart';

class BookingSummaryPage extends StatefulWidget {
  final String parkingId;
  final String parkingName;
  final String slotId;
  final int price;

  const BookingSummaryPage({
    super.key,
    required this.parkingId,
    required this.parkingName,
    required this.slotId,
    required this.price,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  bool _isPaying = false;

  late int _hours;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _hours = 2;
    _startTime = DateTime.now();
  }

  DateTime get _endTime => _startTime.add(Duration(hours: _hours));

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  // ⏱ Time Picker
  Future<void> _openTimePicker() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (_) {
        int tempHours = _hours;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$tempHours hrs',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatTime(_startTime)} - ${_formatTime(_startTime.add(Duration(hours: tempHours)))}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: tempHours > 1
                            ? () => setModalState(() => tempHours--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$tempHours', style: const TextStyle(fontSize: 22)),
                      IconButton(
                        onPressed: () => setModalState(() => tempHours++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempHours),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _hours = result);
    }
  }

  // 💳 START PAYMENT
  Future<void> _startDummyPayment() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DummyPaymentPage(amount: widget.price * _hours),
      ),
    );

    if (success == true) {
      await _confirmBooking();
    } else {
      _toast('Payment cancelled');
    }
  }

  // ✅ CONFIRM BOOKING (NO UI HERE)
  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPaying = true);

    final db = FirebaseFirestore.instance;
    final userDoc = await db.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'User';

    final bookingRef = db.collection('bookings').doc();
    final slotRef = db
        .collection('parkings')
        .doc(widget.parkingId)
        .collection('slots')
        .doc(widget.slotId);

    try {
      await db.runTransaction((tx) async {
        final slotSnap = await tx.get(slotRef);

        if (!slotSnap.exists || slotSnap['available'] != true) {
          throw Exception('Slot not available');
        }

        tx.update(slotRef, {
          'available': false,
          'currentBookingId': bookingRef.id,
        });

        tx.set(bookingRef, {
          'bookingId': bookingRef.id,
          'userId': user.uid,
          'userName': userName,
          'email': user.email,
          'parkingId': widget.parkingId,
          'parkingName': widget.parkingName,
          'slotId': widget.slotId,
          'hours': _hours,
          'startTime': Timestamp.fromDate(_startTime),
          'endTime': Timestamp.fromDate(_endTime),
          'price': widget.price * _hours,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // 📧 EMAIL (NON-BLOCKING)
      EmailService.sendBookingEmail(
        userEmail: user.email!,
        parkingName: widget.parkingName,
        slotId: widget.slotId,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        hours: _hours.toString(),
        price: (widget.price * _hours).toString(),
      ).catchError((e) {
        debugPrint('Email failed: $e');
      });

      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
        _toast('Booking Successful 🎉');
      }
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.parkingName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Slot'), Text(widget.slotId)],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('When do you want to park?'),
              subtitle: Text(
                '${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _openTimePicker,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount'),
                Text(
                  '₹${widget.price * _hours}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _startDummyPayment,
                child: _isPaying
                    ? const CircularProgressIndicator()
                    : const Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
