import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:justparkit/pages/forgot_password_page.dart';
import 'package:justparkit/pages/home_page.dart';
import 'package:justparkit/pages/login_page.dart';
import 'package:justparkit/pages/signup_page.dart';
import 'package:justparkit/pages/start_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JustParkIt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF102960)),
        useMaterial3: true,
      ),
      home: const AuthGate(), // 🔥 START HERE INSTEAD OF '/'
      routes: {
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomePage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/start': (context) => const StartPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ While Firebase checks login session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ If user already logged in → go to Home
        if (snapshot.hasData) {
          return HomePage();
        }

        // ❌ If not logged in → show Start page (Login / Signup options)
        return const StartPage();
      },
    );
  }
}
