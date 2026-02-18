import 'package:flutter/material.dart';
import 'package:justparkit/pages/signup_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000EE0), // Blue background
      body: SafeArea(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Spread top to bottom
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50), // Top spacing
            // Centered Logo + Title
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Fixed: assets path spelling
                // make sure your image is at: assets/images/logo.png and added to pubspec.yaml
                Image.asset("assets/images/logo.png", width: 200, height: 200),
                const SizedBox(height: 20),

                const Text(
                  "JustParkIt",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            // Start Button at the Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102960), // Button color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    debugPrint('Start tapped');
                    // Push SignUpPage onto the stack so user can press back to return here
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Start",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
