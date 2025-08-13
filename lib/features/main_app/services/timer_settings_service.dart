import 'package:shared_preferences/shared_preferences.dart';

class TimerSettingsService {
  static const _workKey = 'work_duration';
  static const _shortBreakKey = 'short_break_duration';
  static const _longBreakKey = 'long_break_duration';
  static const _autoStartKey = 'auto_start';
  static const _titleKey = 'timer_title';

  // --- Lưu Cài đặt ---
  static Future<void> setWorkDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workKey, minutes);
  }
  static Future<void> setShortBreakDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shortBreakKey, minutes);
  }
  static Future<void> setLongBreakDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_longBreakKey, minutes);
  }
  static Future<void> setAutoStart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoStartKey, value);
  }

  // --- Tải Cài đặt ---
  static Future<int> getWorkDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_workKey) ?? 25; // Trả về 25 nếu chưa có giá trị
  }
  static Future<int> getShortBreakDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_shortBreakKey) ?? 5;
  }
  static Future<int> getLongBreakDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longBreakKey) ?? 15;
  }
  static Future<bool> getAutoStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoStartKey) ?? true;
  }

  static Future<void> setTimerTitle(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, title);
  }

  static Future<String> getTimerTitle() async {
    final prefs = await SharedPreferences.getInstance();
    // Trả về 'Focus Task' nếu chưa có gì được lưu
    return prefs.getString(_titleKey) ?? 'Focus Task';
  }

}