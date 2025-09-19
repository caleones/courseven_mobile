import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../pages/home/home_page.dart';
import '../pages/calendar/calendar_page.dart';
import '../pages/account/account_page.dart';
import '../pages/settings/settings_page.dart';

class BottomNavigationDock extends StatelessWidget {
  final int currentIndex;

  const BottomNavigationDock({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home,
            index: 0,
            onTap: () {
              if (currentIndex != 0) {
                Get.offAll(() => const HomePage());
              }
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.calendar_today,
            index: 1,
            onTap: () {
              if (currentIndex != 1) {
                Get.offAll(() => const CalendarPage());
              }
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person,
            index: 2,
            onTap: () {
              if (currentIndex != 2) {
                Get.offAll(() => const AccountPage());
              }
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.settings,
            index: 3,
            onTap: () {
              if (currentIndex != 3) {
                Get.offAll(() => const SettingsPage());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
  }) {
    bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppTheme.goldAccent
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}
