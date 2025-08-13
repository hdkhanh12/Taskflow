import 'package:flutter/material.dart';
import 'package:my_todo_app/features/main_app/presentation/providers/timer_provider.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/timer_setting_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy theme hiện tại để sử dụng
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        final percent = timer.totalSeconds > 0 ? timer.currentSeconds / timer.totalSeconds : 0.0;

        return Scaffold(
          // Lấy màu nền từ theme
          backgroundColor: theme.scaffoldBackgroundColor,
          body: DefaultTextStyle(
            // Lấy style mặc định từ theme
            style: theme.textTheme.bodyMedium!,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pomodoro Timer',
                                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timer.sessionCountText,
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Image.asset(
                                'assets/images/timeredit.png',
                                height: 24,
                                width: 24,
                                // Đổi màu icon edit theo theme
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TimerSettingScreen()),
                                );
                                timer.loadSettingsAndInitialize();
                              },
                            ),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: timer.titleController,
                                textAlign: TextAlign.end,
                                decoration: const InputDecoration(
                                  hintText: 'Title',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Spacer(flex: 2),

                    // Đồng hồ
                    CircularPercentIndicator(
                      radius: 180.0,
                      lineWidth: 18.0,
                      percent: percent,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timer.formattedTime,
                            style: theme.textTheme.displayLarge?.copyWith(fontSize: 60, fontWeight: FontWeight.normal),
                          ),
                          Text(
                            timer.currentStatusText,
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
                          ),
                        ],
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(isDarkMode ? 0.2 : 0.3),
                      progressColor: theme.colorScheme.primaryContainer,
                    ),
                    const Spacer(flex: 1),

                    // Nút điều khiển
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Image.asset(
                            'assets/images/stoptimer.png',
                            height: 32,
                            width: 32,
                            // Đổi màu icon stop theo theme
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: timer.stopTimer,
                        ),
                        const SizedBox(width: 40),
                        IconButton(
                          iconSize: 50,
                          icon: Icon(
                            timer.isTimerRunning ? Icons.pause : Icons.play_arrow,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: timer.isTimerRunning ? timer.pauseTimer : timer.resumeTimer,
                        )
                      ],
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}