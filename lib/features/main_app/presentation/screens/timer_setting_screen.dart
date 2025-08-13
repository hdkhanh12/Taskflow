import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/features/main_app/services/timer_settings_service.dart';

import '../../../../l10n/app_localizations.dart';

class TimerSettingScreen extends StatefulWidget {
  const TimerSettingScreen({super.key});

  @override
  State<TimerSettingScreen> createState() => _TimerSettingScreenState();
}

class _TimerSettingScreenState extends State<TimerSettingScreen> {
  int _workDuration = 25;
  int _shortBreak = 5;
  int _longBreak = 15;
  bool _autoStart = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    _workDuration = await TimerSettingsService.getWorkDuration();
    _shortBreak = await TimerSettingsService.getShortBreakDuration();
    _longBreak = await TimerSettingsService.getLongBreakDuration();
    _autoStart = await TimerSettingsService.getAutoStart();
    setState(() {});
  }

  void _saveSettings() {
    TimerSettingsService.setWorkDuration(_workDuration);
    TimerSettingsService.setShortBreakDuration(_shortBreak);
    TimerSettingsService.setLongBreakDuration(_longBreak);
    TimerSettingsService.setAutoStart(_autoStart);
    Navigator.of(context).pop();
  }

  void _showDurationPicker(String title, int initialValue, ValueChanged<int> onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 250,
        child: CupertinoPicker(
          itemExtent: 40,
          scrollController: FixedExtentScrollController(initialItem: initialValue - 1),
          onSelectedItemChanged: onSelected,
          children: List.generate(60, (i) => Center(child: Text('${i + 1} min'))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveSettings,
                  ),
                ],
              ),
            ),
            // Tiêu đề
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                AppLocalizations.of(context)!.timerSetting,
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32, fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(height: 20),
            // Danh sách cài đặt
            Expanded(
              child: ListView(
                children: [
                  _buildSettingTile(
                    context,
                    AppLocalizations.of(context)!.workSession,
                    '$_workDuration min',
                        () => _showDurationPicker('Work Session', _workDuration, (val) => setState(() => _workDuration = val + 1)),
                  ),
                  _buildSettingTile(
                    context,
                    AppLocalizations.of(context)!.shortBreaksession,
                    '$_shortBreak min',
                        () => _showDurationPicker('Short Break', _shortBreak, (val) => setState(() => _shortBreak = val + 1)),
                  ),
                  _buildSettingTile(
                    context,
                    AppLocalizations.of(context)!.longBreaksession,
                    '$_longBreak min',
                        () => _showDurationPicker('Long Break', _longBreak, (val) => setState(() => _longBreak = val + 1)),
                  ),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.autoStartWorkSession, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    value: _autoStart,
                    onChanged: (val) => setState(() => _autoStart = val),
                    // secondary: Text(_autoStart ? 'On' : 'Off', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, String value, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      trailing: Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      onTap: onTap,
    );
  }
}