import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/account_screen.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_settings_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../services/user_service.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Thêm biến state cho cài đặt thông báo
  bool _areNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    _areNotificationsEnabled = await NotificationSettingsService.getNotificationsEnabled();
    if (mounted) setState(() {});
  }

  // Thêm hàm này vào trong class của SettingsScreen

  void _showLanguagePicker(BuildContext context) {
    // Lấy provider, listen: false vì đang ở trong một hàm
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Text('🇬🇧'),
              title: const Text('English'),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇻🇳'),
              title: const Text('Tiếng Việt'),
              onTap: () {
                localeProvider.setLocale(const Locale('vi'));
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userService = UserService();
    final currentUser = FirebaseAuth.instance.currentUser;

        return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        // elevation: 0,
        // leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Lắng nghe dữ liệu người dùng
        stream: userService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final displayName = userData['displayName'] ?? currentUser?.displayName ?? 'User';

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(AppLocalizations.of(context)!.accountSectionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                  backgroundColor: userData['avatarBackgroundColorValue'] != null
                      ? Color(userData['avatarBackgroundColorValue'])
                      : Colors.grey[200],
                  child: currentUser?.photoURL == null && userData['avatarIconPath'] != null
                      ? SvgPicture.asset(userData['avatarIconPath'], height: 24, width: 24)
                      : (currentUser?.photoURL == null ? Text(displayName.substring(0, 1).toUpperCase()) : null),
                ),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Personal Information'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
                },
              ),
              const Divider(height: 40),

              // --- Khu vực Settings ---
              Text(AppLocalizations.of(context)!.settingsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Trong ListView của SettingsScreen

              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.languageSettingTitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hiển thị ngôn ngữ hiện tại
                    Text(
                      AppLocalizations.of(context)!.currentLanguage,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () {
                  // Mở pop-up chọn ngôn ngữ
                  _showLanguagePicker(context);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(AppLocalizations.of(context)!.notification),
                value: _areNotificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _areNotificationsEnabled = value;
                  });
                  NotificationSettingsService.setNotificationsEnabled(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.brightness_6_outlined),
                title: Text(AppLocalizations.of(context)!.darkMode),
                // Lấy giá trị từ provider
                value: themeProvider.themeMode == ThemeMode.dark,
                // Khi thay đổi, gọi hàm trong provider
                onChanged: (value) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(AppLocalizations.of(context)!.help),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
                  );
                },
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(AppLocalizations.of(context)!.logout),
                onTap: () async {
                  // Hiển thị hộp thoại xác nhận
                  final bool? confirmLogout = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.confirmlogout),
                      content: Text(AppLocalizations.of(context)!.confirmlogouttext),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(AppLocalizations.of(context)!.logout, style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmLogout == true) {
                    // Gọi hàm signOut từ service
                    await AuthService().signOut();
                    if (mounted) {
                      // Điều hướng về màn hình Login sau khi đăng xuất
                      // pushAndRemoveUntil sẽ xóa hết các màn hình cũ
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()), // Cần import LoginScreen
                            (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
