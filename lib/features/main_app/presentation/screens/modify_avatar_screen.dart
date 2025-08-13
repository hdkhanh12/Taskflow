import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_todo_app/core/constants/app_icons.dart';
import 'package:my_todo_app/features/main_app/services/user_service.dart';

import '../../../../l10n/app_localizations.dart';

class ModifyAvatarScreen extends StatefulWidget {
  const ModifyAvatarScreen({super.key});

  @override
  State<ModifyAvatarScreen> createState() => _ModifyAvatarScreenState();
}

class _ModifyAvatarScreenState extends State<ModifyAvatarScreen> {
  final UserService _userService = UserService();
  final List<Color> _colors = [
    const Color(0xFFC9E4DE), const Color(0xFFC6E2E9), const Color(0xFFFFF2D1),
    const Color(0xFFFDE7E5), const Color(0xFFE5DEFE), const Color(0xFFFFD9D9),
  ];

  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;

  void _saveAvatar() async {
    await _userService.updateUserProfile({
      'avatarBackgroundColorValue': _colors[_selectedColorIndex].value,
      'avatarIconPath': AppIcons.avatarIcons[_selectedIconIndex],
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Xóa title khỏi AppBar
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: _saveAvatar,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              AppLocalizations.of(context)!.modifyAvatar,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(height: 50.0), // For 50 logical pixels of vertical space
          // const Spacer(),
          // Avatar preview
          CircleAvatar(
            radius: 130,
            backgroundColor: _colors[_selectedColorIndex],
            child: SvgPicture.asset(
              AppIcons.avatarIcons[_selectedIconIndex],
              height: 180,
              width: 180,
            ),
          ),
          const Spacer(),

          // Bảng màu
          SizedBox(
            height: 50,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Kích thước mỗi item + khoảng cách (dùng double rõ ràng)
                const double itemSize = 36.0; // đường kính CircleAvatar
                const double spacing = 12.0;
                final double totalWidth = _colors.length * itemSize + (_colors.length - 1) * spacing;

                // Nếu tổng chiều rộng < màn hình => padding 2 bên để căn giữa
                final double horizontalPadding = totalWidth < constraints.maxWidth
                    ? (constraints.maxWidth - totalWidth) / 2.0
                    : 24.0; // nếu dài hơn thì để padding mặc định

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: _colors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: CircleAvatar(
                        radius: itemSize / 2,
                        backgroundColor: _colors[index],
                        child: _selectedColorIndex == index
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Lưới icon
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: AppIcons.avatarIcons.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconIndex = index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIconIndex == index ? _colors[_selectedColorIndex].withOpacity(0.9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        AppIcons.avatarIcons[index],
                      )
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}