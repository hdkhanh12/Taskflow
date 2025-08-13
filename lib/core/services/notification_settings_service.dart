import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const _enabledKey = 'notifications_enabled';

  // Lưu cài đặt
  static Future<void> setNotificationsEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, isEnabled);
  }

  // Tải cài đặt
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true; // Mặc định là bật
  }
}