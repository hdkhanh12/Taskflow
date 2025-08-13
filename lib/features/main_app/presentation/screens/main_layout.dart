import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/home_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/note_list_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/task_list_screen.dart';
import 'package:my_todo_app/features/main_app/presentation/screens/timer_screen.dart';
import 'package:my_todo_app/core/services/push_notification_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    PushNotificationService().initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const TaskListScreen(),
    const NoteListScreen(),
    const TimerScreen(),
  ];

  // In your _MainLayoutState class, inside the build method:
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Dot color remains as you had it, this seems fine
    final dotColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        // Khi người dùng vuốt, cập nhật lại index của BottomNavigationBar
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Khi nhấn vào một tab, chuyển trang trong PageView
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.canvasColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 5,
        items: [
          _buildNavItem(
            iconName: 'Homepage_icon',
            index: 0,
            // Pass the determined color for the ColorFilter directly,
            // or null if no filter (use original SVG color)
            iconFilterColor: isDarkMode ? Colors.white : null,
            dotColor: dotColor,
          ),
          _buildNavItem(
            iconName: 'TaskList_icon',
            index: 1,
            iconFilterColor: isDarkMode ? Colors.white : null,
            dotColor: dotColor,
          ),
          _buildNavItem(
            iconName: 'NoteLists_icon',
            index: 2,
            iconFilterColor: isDarkMode ? Colors.white : null,
            dotColor: dotColor,
          ),
          _buildNavItem(
            iconName: 'Timer_icon',
            index: 3,
            iconFilterColor: isDarkMode ? Colors.white : null,
            dotColor: dotColor,
          ),
        ],
      ),
    );
  }

// Adjusted _buildNavItem helper function:
  BottomNavigationBarItem _buildNavItem({
    required int index,
    required String iconName,
    required Color? iconFilterColor, // Nullable Color for the filter
    required Color dotColor,
  }) {
    final isSelected = _currentIndex == index;
    final String iconSuffix = isSelected ? '2' : '1'; // selected: icon2, unselected: icon1

    // Determine the ColorFilter based on iconFilterColor
    final ColorFilter? colorFilter =
    iconFilterColor != null ? ColorFilter.mode(iconFilterColor, BlendMode.srcIn) : null;

    return BottomNavigationBarItem(
      label: iconName, // Label is not shown but good for semantics
      icon: SvgPicture.asset(
        'assets/images/${iconName}1.svg', // Always use icon1 for the 'icon' property
        height: 24,
        width: 24,
        colorFilter: colorFilter, // Apply the determined filter
      ),
      activeIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/${iconName}2.svg', // Always use icon2 for the 'activeIcon' property
            height: 24,
            width: 24,
            colorFilter: colorFilter, // Apply the determined filter
          ),
          const SizedBox(height: 4),
          Container(
            height: 5,
            width: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

}