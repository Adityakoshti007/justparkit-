import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:justparkit/admin/add_slots_page.dart';

class AddParkingPage extends StatefulWidget {
  const AddParkingPage({super.key});

  @override
  State<AddParkingPage> createState() => _AddParkingPageState();
}

class _AddParkingPageState extends State<AddParkingPage> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();

  bool _loading = false;

  // 💾 Save Parking (NO IMAGE)
  Future<void> _saveParking() async {
    if (_loading) return; // 🔴 CRITICAL LINE

    if (_nameCtrl.text.isEmpty ||
        _cityCtrl.text.isEmpty ||
        _latCtrl.text.isEmpty ||
        _lngCtrl.text.isEmpty ||
        _priceCtrl.text.isEmpty ||
        _ratingCtrl.text.isEmpty) {
      _toast('Please fill all fields');
      return;
    }

    setState(() => _loading = true);

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('parkings')
          .add({
            'name': _nameCtrl.text.trim(),
            'city': _cityCtrl.text.trim().toLowerCase(),
            'latitude': double.parse(_latCtrl.text),
            'longitude': double.parse(_lngCtrl.text),
            'price': int.parse(_priceCtrl.text),
            'rating': double.parse(_ratingCtrl.text),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      // 🔴 VERY IMPORTANT: STOP EXECUTION AFTER NAVIGATION
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddSlotsPage(parkingId: docRef.id)),
      );

      return; // 🔴 THIS LINE PREVENTS DOUBLE EXECUTION
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parking (Admin)'),
        backgroundColor: const Color(0xFF4B4BE0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(_nameCtrl, 'Parking Name'),
            _input(_cityCtrl, 'City / Area'),
            _input(_latCtrl, 'Latitude', keyboard: TextInputType.number),
            _input(_lngCtrl, 'Longitude', keyboard: TextInputType.number),
            _input(
              _priceCtrl,
              'Price per hour',
              keyboard: TextInputType.number,
            ),
            _input(
              _ratingCtrl,
              'Rating (e.g. 4.5)',
              keyboard: TextInputType.number,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B4BE0),
                ),
                onPressed: _loading ? null : _saveParking,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE PARKING'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
