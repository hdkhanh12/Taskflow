import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:my_todo_app/features/main_app/services/timer_settings_service.dart';

enum PomodoroState { work, shortBreak, longBreak, paused }

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  final TextEditingController titleController = TextEditingController();

  // --- Cài đặt ---
  int _workDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;
  int _longBreakDuration = 15 * 60;
  bool _autoStart = true;
  final int _sessionsBeforeLongBreak = 4;

  // --- Trạng thái ---
  int _currentSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  PomodoroState _currentState = PomodoroState.work;
  int _completedSessions = 0;
  PomodoroState _stateBeforePause = PomodoroState.work;

  // --- Getters để UI truy cập ---
  int get currentSeconds => _currentSeconds;
  int get totalSeconds => _totalSeconds;
  PomodoroState get currentState => _currentState;
  bool get isTimerRunning => _timer?.isActive ?? false;
  String get sessionCountText => 'Pomodoro ${_completedSessions % _sessionsBeforeLongBreak + 1}/$_sessionsBeforeLongBreak';

  String get formattedTime {
    final min = (_currentSeconds / 60).floor().toString().padLeft(2, '0');
    final sec = (_currentSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String get currentStatusText {
    if (isTimerRunning) return 'Time Remaining';
    switch (_currentState) {
      case PomodoroState.work: return 'Work Session';
      case PomodoroState.shortBreak: return 'Short Break';
      case PomodoroState.longBreak: return 'Long Break';
      case PomodoroState.paused: return 'Paused';
    }
  }

  TimerProvider() {
    // Tải cài đặt và lắng nghe sự thay đổi của title
    loadSettingsAndInitialize();
    titleController.addListener(_saveTitle);
  }

  @override
  void dispose() {
    titleController.removeListener(_saveTitle);
    titleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _saveTitle() {
    TimerSettingsService.setTimerTitle(titleController.text);
  }

  // --- Các hàm điều khiển ---
  Future<void> loadSettingsAndInitialize() async {
    _workDuration = (await TimerSettingsService.getWorkDuration()) * 60;
    _shortBreakDuration = (await TimerSettingsService.getShortBreakDuration()) * 60;
    _longBreakDuration = (await TimerSettingsService.getLongBreakDuration()) * 60;
    _autoStart = await TimerSettingsService.getAutoStart();

    // Tải title đã lưu và gán vào controller
    titleController.text = await TimerSettingsService.getTimerTitle();

    stopTimer();
  }

  void startTimer({int? startSeconds, required PomodoroState newState}) {
    _timer?.cancel();
    _currentState = newState;
    _totalSeconds = startSeconds ?? _totalSeconds;
    _currentSeconds = _totalSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        _currentSeconds--;
      } else {
        timer.cancel();
        _startNextSession();
      }
      notifyListeners(); // Cập nhật UI mỗi giây
    });
    notifyListeners();
  }

  void pauseTimer() {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      _stateBeforePause = _currentState;
      _currentState = PomodoroState.paused;
      notifyListeners();
    }
  }

  void resumeTimer() {
    startTimer(startSeconds: _currentSeconds, newState: _stateBeforePause);
  }

  void stopTimer() {
    _timer?.cancel();
    _currentState = PomodoroState.work;
    _currentSeconds = _workDuration;
    _totalSeconds = _workDuration;
    _completedSessions = 0;
    notifyListeners();
  }

  void _startNextSession() {
    FlutterRingtonePlayer().playNotification();

    if (_currentState == PomodoroState.work) {
      _completedSessions++;
    }

    if (_completedSessions % _sessionsBeforeLongBreak == 0 && _currentState != PomodoroState.longBreak) {
      startTimer(startSeconds: _longBreakDuration, newState: PomodoroState.longBreak);
    } else if (_currentState == PomodoroState.work || _currentState == PomodoroState.paused) {
      startTimer(startSeconds: _shortBreakDuration, newState: PomodoroState.shortBreak);
    } else {
      if (_autoStart) {
        startTimer(startSeconds: _workDuration, newState: PomodoroState.work);
      } else {
        stopTimer();
      }
    }
  }
}