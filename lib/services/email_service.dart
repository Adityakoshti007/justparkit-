import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  static Future<void> sendBookingEmail({
    required String userEmail,
    required String parkingName,
    required String slotId,
    required String startTime,
    required String endTime,
    required String hours,
    required String price,
  }) async {
    const serviceId = 'service_0628bx5';
    const templateId = 'template_g2ulfg7'; // 👈 YOUR REAL TEMPLATE ID
    const publicKey = 'FreV7yiKkvuw_U-RV';

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'email': userEmail, // ✅ REQUIRED
          'parking_name': parkingName,
          'slot_id': slotId,
          'start_time': startTime,
          'end_time': endTime,
          'hours': hours,
          'price': price,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('EmailJS failed: ${response.body}');
    }
  }
}
