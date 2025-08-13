import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    // Dùng Future.delayed để đảm bảo màn hình chờ hiển thị
    Future.delayed(const Duration(milliseconds: 1500), () {
      // Lắng nghe sự thay đổi trạng thái đăng nhập
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (mounted) {
          if (user == null) {
            // Nếu không có người dùng, đi đến màn hình Onboarding
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          } else {
            // Nếu có người dùng, đi thẳng vào màn hình chính
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 300,
        ),
      ),
    );
  }
}