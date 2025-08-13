import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:my_todo_app/features/auth/services/auth_service.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/main_layout.dart';

import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        print("Đăng nhập thành công! User ID: ${user.uid}");
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Hiển thị thông báo lỗi cho người dùng
      String message;
      if (e.code == 'email-not-verified') {
        message = 'Vui lòng xác thực email của bạn. Một email mới đã được gửi.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else {
        message = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    const Color primaryColor = Color(0xFF7B61FF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Tiêu đề
            RichText(
              text: TextSpan(
                // style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E), fontFamily: 'Poppins'),
                style: theme.textTheme.headlineMedium,
                children: [
                  const TextSpan(text: 'Log In to '),
                  TextSpan(
                    text: 'TaskFlow',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Ô nhập Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Ô nhập Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            // ===================================

            const SizedBox(height: 40),

            // Nút Log in
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin, // Vô hiệu hóa nút khi đang loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C77BF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Log in', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 30),

            // Dải phân cách "or"
            Row(
              children: [
                Expanded(child: Divider(thickness: 1, color: isDarkMode ? Colors.white54 : Colors.black26)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black45,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(thickness: 1, color: isDarkMode ? Colors.white54 : Colors.black26)),
              ],
            ),
            const SizedBox(height: 30),

            // Icon mạng xã hội
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Image.asset('assets/images/facebook_logo.png', height: 40),
                  onPressed: () {
                    // Show a SnackBar when the button is pressed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coming soon!'),
                        duration: Duration(seconds: 2), // Optional: How long the SnackBar is visible
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Image.asset('assets/images/google_logo.png', height: 40),
                  onPressed: () async {
                    // Bắt đầu loading (tùy chọn, nhưng nên có để trải nghiệm tốt hơn)
                    setState(() => _isLoading = true);

                    try {
                      final user = await _authService.signInWithGoogle();
                      if (user != null && mounted) {
                        // Đăng nhập thành công, chuyển đến trang chủ
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainLayout()),
                        );
                      }
                    } catch (e) {
                      // Hiển thị lỗi nếu có
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    } finally {
                      // Dừng loading dù thành công hay thất bại
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Image.asset('assets/images/apple_logo.png', height: 40),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Các link chuyển tiếp
            Center(
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      // style: const TextStyle(color: Color(0xFF2A2A2A), fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Poppins'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      children: [
                        const TextSpan(text: 'Forgot your password? '),
                        TextSpan(
                          text: 'Reset it.',
                          // style: const TextStyle(color: Color(0xFF434F82), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      // style: const TextStyle(color: Color(0xFF2A2A2A), fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Poppins'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      children: [
                        const TextSpan(text: 'Doesn’t have an account? '),
                        TextSpan(
                          text: 'Sign up.',
                          // style: const TextStyle(color: Color(0xFF434F82), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}