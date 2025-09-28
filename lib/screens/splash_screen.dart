import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // small splash delay

    try {
      // ✅ Wait for Firebase to fully restore user session
      final user = await FirebaseAuth.instance.authStateChanges().first;

      if (!mounted) return;

      if (user == null) {
        // 🚪 No session -> go to LoginPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      // ✅ User session exists, check Firestore role
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['role'] == 'admin') {
        // 🔑 Logged in as admin -> go to AdminDashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(onThemeChanged: (_) {}),
          ),
          (route) => false,
        );
      } else {
        // 👤 Normal user -> go to HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      // If something goes wrong -> send to login page
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/loggos.jpeg", height: 120),
            const SizedBox(height: 20),
            const Text(
              "MBBSFreaks",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.purple,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
