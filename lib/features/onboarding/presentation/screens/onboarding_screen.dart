import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:my_todo_app/features/auth/presentation/screens/signup_screen.dart';

import '../../../auth/presentation/screens/login_screen.dart';

// import 'package:my_todo_app/features/2_auth/presentation/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controller để điều khiển PageView
  final _pageController = PageController();

  // Biến để kiểm tra xem có phải trang cuối cùng không
  bool _isLastPage = false;

  final List<Widget> _onboardingPages = const [
    OnboardingPageContent(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'Welcome to Taskflow!',
      subtitle: 'Experience a smoother way to manage tasks and find your daily rhythm.',
    ),
    OnboardingPageContent(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'Capture Ideas Instantly.',
      subtitle: 'Quickly add tasks, notes, and reminders whenever inspiration strikes. Never miss a thing.',
    ),
    OnboardingPageContent(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'Organize Your Way.',
      subtitle: 'Group tasks by project, priority, or due date. Stay effortlessly organized and in control.',
    ),
    OnboardingPageContent(
      imagePath: 'assets/images/onboarding_4.png',
      title: 'Focus and Achieve.',
      subtitle: 'Minimize distractions, track your progress, and celebrate your accomplishments.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()), // <-- Thay đổi ở đây
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                  ),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: const Text('Skips', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      // Logic mới: Tự động kiểm tra trang cuối cùng
                      _isLastPage = index == _onboardingPages.length - 1;
                    });
                  },
                  children: _onboardingPages,
                ),
              ),
              SmoothPageIndicator(
                controller: _pageController,
                // Logic mới: Tự động lấy số lượng trang
                count: _onboardingPages.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Color(0xFF7B61FF),
                  dotColor: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isLastPage) {
                      _navigateToLogin(); // <-- Bây giờ sẽ hoạt động
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLastPage ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


/// WIDGET TÁI SỬ DỤNG CHO NỘI DUNG MỖI TRANG
class OnboardingPageContent extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const OnboardingPageContent({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, height: MediaQuery.of(context).size.height * 0.35),
        const SizedBox(height: 40),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C77BF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}