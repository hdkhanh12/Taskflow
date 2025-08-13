import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_todo_app/features/main_app/services/user_service.dart';

import '../../../../l10n/app_localizations.dart';
import 'modify_avatar_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserService _userService = UserService();
  final _nameController = TextEditingController();

  String _initialName = '';

  void _saveProfile() async {
    final newName = _nameController.text.trim();

    // Chỉ cập nhật nếu tên đã thay đổi
    if (newName.isNotEmpty && newName != _initialName) {
      await _userService.updateUserProfile({'displayName': newName});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdateNotification)),
      );
      Navigator.of(context).pop();
    }
  }

  void _showGenderPicker() {
    // Dùng showModalBottomSheet để có hiệu ứng trượt lên từ dưới
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.selectGender, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...[AppLocalizations.of(context)!.male, AppLocalizations.of(context)!.female, AppLocalizations.of(context)!.other].map((gender) {
                return ListTile(
                  title: Text(gender),
                  onTap: () async {
                    await _userService.updateUserProfile({'gender': gender});
                    if (mounted) Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: _saveProfile,
          ),
        ],
      ),
      // Dùng StreamBuilder để tự động cập nhật khi dữ liệu thay đổi
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Lấy dữ liệu, nếu không có thì trả về map rỗng
          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final user = FirebaseAuth.instance.currentUser;

          // Cập nhật controller với dữ liệu mới nhất
          _initialName = userData['displayName'] ?? user?.displayName ?? '';
          _nameController.text = _initialName;
          final currentGender = userData['gender'] ?? 'Not set';

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(AppLocalizations.of(context)!.accountSectionTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E) ,fontFamily: 'Poppins')),
              const SizedBox(height: 32),
              // Vùng ảnh đại diện
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      backgroundColor: userData['avatarBackgroundColorValue'] != null
                          ? Color(userData['avatarBackgroundColorValue'])
                          : Colors.grey[200],
                      child: user?.photoURL == null && userData['avatarIconPath'] != null
                          ? SvgPicture.asset(userData['avatarIconPath'], height: 40, width: 40)
                          : (user?.photoURL == null ? const Icon(Icons.person, size: 40) : null),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModifyAvatarScreen()));
                      },
                      child: Text(AppLocalizations.of(context)!.modifyAvatar),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Ô nhập liệu cho Tên
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.name,
                ),
              ),
              const SizedBox(height: 16),

              _buildInfoRow(
                AppLocalizations.of(context)!.gender,
                currentGender,
                onTap: _showGenderPicker,
              ),
              _buildInfoRow(AppLocalizations.of(context)!.connectedAccounts, user?.providerData.first.providerId ?? 'Email'),
              _buildInfoRow('Email', user?.email ?? 'No email'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Inter',fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF837F7D))),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}