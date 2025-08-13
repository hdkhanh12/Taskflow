import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_todo_app/features/main_app/services/user_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final UserService _userService = UserService();

  Future<void> initialize() async {
    // 1. Yêu cầu quyền gửi thông báo từ người dùng
    await _fcm.requestPermission();

    // 2. Lấy FCM Token của thiết bị
    final fcmToken = await _fcm.getToken();
    print("FCM Token: $fcmToken");

    // 3. Lưu token này vào document của người dùng trên Firestore
    if (fcmToken != null) {
      _userService.updateUserProfile({'fcmToken': fcmToken});
    }

    // 4. Lắng nghe token thay đổi và cập nhật lại
    _fcm.onTokenRefresh.listen((newToken) {
      _userService.updateUserProfile({'fcmToken': newToken});
    });
  }
}