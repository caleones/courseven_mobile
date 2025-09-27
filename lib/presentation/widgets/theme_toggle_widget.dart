import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:courseven/presentation/controllers/theme_controller.dart';

class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: themeController.isDarkMode
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              GestureDetector(
                onTap: () => themeController.setLightTheme(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: !themeController.isDarkMode
                        ? Colors.yellow[700]
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.light_mode,
                    color: !themeController.isDarkMode
                        ? Colors.white
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),

              
              GestureDetector(
                onTap: () => themeController.setDarkTheme(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: themeController.isDarkMode
                        ? Colors.yellow[700]
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.dark_mode,
                    color: themeController.isDarkMode
                        ? Colors.white
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
