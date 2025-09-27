import 'package:flutter/material.dart';
import '../theme/app_theme.dart';


class FloatingActionMenu extends StatefulWidget {
  const FloatingActionMenu({super.key});

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        SizeTransition(
          sizeFactor: _scale,
          axisAlignment: -1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                icon: Icons.school,
                label: 'Crear Curso',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.category,
                label: 'Crear Categoría',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.assignment,
                label: 'Crear Actividad',
                onTap: () {},
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        
        FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: AppTheme.goldAccent,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.add,
              color: AppTheme.premiumBlack,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.goldAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: onTap,
            backgroundColor: AppTheme.goldAccent.withOpacity(0.9),
            child: Icon(
              icon,
              color: AppTheme.premiumBlack,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
