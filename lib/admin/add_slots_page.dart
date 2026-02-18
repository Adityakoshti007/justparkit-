import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSlotsPage extends StatefulWidget {
  final String parkingId;

  const AddSlotsPage({super.key, required this.parkingId});

  @override
  State<AddSlotsPage> createState() => _AddSlotsPageState();
}

class _AddSlotsPageState extends State<AddSlotsPage> {
  final TextEditingController _countCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _addSlots() async {
    if (_loading) return;

    final int count = int.tryParse(_countCtrl.text) ?? 0;
    final int price = int.tryParse(_priceCtrl.text) ?? 0;

    if (count <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid slot count')));
      return;
    }

    setState(() => _loading = true);

    try {
      final slotsRef = FirebaseFirestore.instance
          .collection('parkings')
          .doc(widget.parkingId)
          .collection('slots');

      // 🔥 get existing slots count
      final existingSnap = await slotsRef.get();
      final int existingCount = existingSnap.docs.length;

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 1; i <= count; i++) {
        final slotNumber = existingCount + i;
        batch.set(slotsRef.doc('S$slotNumber'), {
          'available': true,
          'price': price,
          'currentBookingId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      // ✅ clear fields for next entry
      _countCtrl.clear();
      _priceCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slots added. You can add more.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Slots'),
        backgroundColor: const Color(0xFF4B4BE0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of slots'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price per slot'),
            ),
            const SizedBox(height: 24),

            // ➕ ADD MORE SLOTS
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _addSlots,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ADD MORE SLOTS'),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ DONE BUTTON
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
