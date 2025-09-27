import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../pages/home/home_page.dart';
import '../pages/calendar/calendar_page.dart';
import '../pages/account/account_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/notifications/notifications_page.dart';

class BottomNavigationDock extends StatelessWidget {
  final int currentIndex; 
  
  final bool hasNewNotifications;

  const BottomNavigationDock({
    super.key,
    required this.currentIndex,
    this.hasNewNotifications = false,
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
          
          _buildNotificationsItem(context: context, index: 2),
          _buildNavItem(
            context: context,
            icon: Icons.person,
            index: 3,
            onTap: () {
              if (currentIndex != 3) {
                Get.offAll(() => const AccountPage());
              }
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.settings,
            index: 4,
            onTap: () {
              if (currentIndex != 4) {
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
    bool isSelected = currentIndex >= 0 && index == currentIndex;

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

  
  Widget _buildNotificationsItem(
      {required BuildContext context, required int index}) {
    final isSelected = index == currentIndex;
    return Tooltip(
      message: hasNewNotifications
          ? 'Tienes nuevas notificaciones'
          : 'Notificaciones',
      child: GestureDetector(
        onTap: () {
          if (currentIndex != index) {
            Get.offAll(() => const NotificationsPage());
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.goldAccent.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? Icons.notifications : Icons.notifications_none,
                color: isSelected
                    ? AppTheme.goldAccent
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              if (hasNewNotifications)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldAccent.withOpacity(0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
