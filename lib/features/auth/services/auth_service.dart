import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Trả về đối tượng User nếu thành công, trả về null nếu thất bại.
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      // 1. Dùng Firebase để tạo tài khoản mới từ email và mật khẩu
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Lấy đối tượng User vừa được tạo
      User? user = userCredential.user;

      // 3. Nếu tạo thành công và user chưa xác thực email...
      if (user != null && !user.emailVerified) {
        // ...gửi email xác nhận (chứa đường link)
        await user.sendEmailVerification();
        print('Sign-up successful. Verification email sent to $email');
      }

      // 4. Trả về đối tượng user để có thể sử dụng ở nơi gọi hàm
      return user;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('Error: The password is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('Error: This email is already in use.');
      } else {
        print('Sign-up error: ${e.message}');
      }
      return null;
    } catch (e) {
      print('An unknown error occurred: $e');
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // 1. Dùng Firebase để đăng nhập
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // 2. Kiểm tra xem người dùng đã xác thực email hay chưa
      if (user != null && !user.emailVerified) {
        // Nếu chưa xác thực, gửi lại email và báo lỗi
        await user.sendEmailVerification();
        // Ném ra một lỗi để UI có thể bắt và hiển thị thông báo
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email. A new email has been sent.',
        );
      }

      // 3. Nếu đăng nhập và đã xác thực thành công, trả về user
      return user;

    } on FirebaseAuthException catch (e) {
      // In ra lỗi để debug và ném ra lại để UI xử lý
      print("Firebase sign-in error: ${e.code}");
      // Ném ra lỗi để UI có thể hiển thị thông báo phù hợp
      throw e;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print("Password reset link sent successfully.");
    } on FirebaseAuthException catch (e) {
      // Ném ra lỗi để UI có thể bắt và hiển thị thông báo
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else {
        throw Exception('An error occurred. Please try again.');
      }
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Tạo một thực thể của GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 2. Bắt đầu quy trình đăng nhập và lấy tài khoản
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("Google sign-in was cancelled.");
        return null;
      }

      // 3. Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Tạo credential cho Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Đăng nhập vào Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      print("Google sign-in successful: ${userCredential.user?.displayName}");
      return userCredential.user;

    } catch (e) {
      print("An error occurred during Google sign-in: $e");
      return null;
    }
  }

  // Trong class AuthService

  Future<void> signOut() async {
    try {
      // Đăng xuất khỏi Google trước để đảm bảo phiên được xóa
      await GoogleSignIn().signOut();
      // Sau đó đăng xuất khỏi Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

}