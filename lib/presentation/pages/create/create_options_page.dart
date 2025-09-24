import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'category_create_page.dart';
import 'group_create_page.dart';
import 'course_create_page.dart';
import 'activity_create_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_navigation_dock.dart';

class CreateOptionsPage extends StatelessWidget {
  const CreateOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppTheme.goldAccent, size: 20),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Qué deseas crear?',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(.75))),
                      const SizedBox(height: 4),
                      Text('Crear',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _CreateTile(
                label: 'Crear curso',
                icon: Icons.school,
                color: Colors.blue,
                onTap: () => Get.to(() => const CourseCreatePage()),
              ),
              const SizedBox(height: 12),
              _CreateTile(
                label: 'Crear actividad',
                icon: Icons.task_alt,
                color: Colors.purple,
                onTap: () => Get.to(() => const ActivityCreatePage()),
              ),
              const SizedBox(height: 12),
              _CreateTile(
                label: 'Crear categoría',
                icon: Icons.category,
                color: Colors.orange,
                onTap: () => Get.to(() => const CategoryCreatePage()),
              ),
              const SizedBox(height: 12),
              _CreateTile(
                label: 'Crear grupo',
                icon: Icons.groups,
                color: Colors.green,
                onTap: () => Get.to(() => const GroupCreatePage()),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationDock(
        currentIndex: -1,
        hasNewNotifications: true,
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CreateTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
