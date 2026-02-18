import 'dart:async';
import 'package:flutter/material.dart';

class DummyPaymentPage extends StatefulWidget {
  final int amount;

  const DummyPaymentPage({super.key, required this.amount});

  @override
  State<DummyPaymentPage> createState() => _DummyPaymentPageState();
}

class _DummyPaymentPageState extends State<DummyPaymentPage> {
  bool _isProcessing = false;

  void _paySuccess() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context, true); // SUCCESS
  }

  void _payFailure() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context, false); // FAILURE
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, size: 80),
            const SizedBox(height: 16),
            Text(
              'Pay ₹${widget.amount}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            if (_isProcessing)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _paySuccess,
                  child: const Text('Pay (Success)'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _payFailure,
                  child: const Text('Pay (Fail)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
