import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import '../theme/app_theme.dart';import '../theme/app_theme.dart';

class FloatingActionMenu extends StatefulWidget {

  const FloatingActionMenu({super.key});



  @overrideclass FloatingActionMenu extends StatefulWidget {class FloatingActionMenu extends StatefulWidget {

  State<FloatingActionMenu> createState() => _FloatingActionMenuState();

}  const FloatingActionMenu({super.key});  const FloatingActionMenu({super.key});



class _FloatingActionMenuState extends State<FloatingActionMenu>

    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;  @override  @override

  late Animation<double> _animation;

  bool _isExpanded = false;  State<FloatingActionMenu> createState() => _FloatingActionMenuState();  State<FloatingActionMenu> createState() => _FloatingActionMenuState();



  @override}}

  void initState() {

    super.initState();

    _animationController = AnimationController(

      duration: const Duration(milliseconds: 300),class _FloatingActionMenuState extends State<FloatingActionMenu>class _FloatingActionMenuState extends State<FloatingActionMenu>

      vsync: this,

    );    with SingleTickerProviderStateMixin {    with SingleTickerProviderStateMixin {

    _animation = CurvedAnimation(

      parent: _animationController,  late AnimationController _animationController;  late AnimationController _animationController;

      curve: Curves.easeInOut,

    );  late Animation<double> _animation;  late Animation<double> _animation;

  }

  bool _isExpanded = false;  bool _isExpanded = false;

  @override

  void dispose() {

    _animationController.dispose();

    super.dispose();  @override  @override

  }

  void initState() {  void initState() {

  void _toggleMenu() {

    if (_isExpanded) {    super.initState();    super.initState();

      _animationController.reverse();

    } else {    _animationController = AnimationController(    _animationController = AnimationController(

      _animationController.forward();

    }      duration: const Duration(milliseconds: 300),      duration: const Duration(milliseconds: 300),

    setState(() {

      _isExpanded = !_isExpanded;      vsync: this,      vsync: this,

    });

  }    );    );



  @override    _animation = CurvedAnimation(    _animation = CurvedAnimation(

  Widget build(BuildContext context) {

    return Column(      parent: _animationController,      parent: _animationController,

      mainAxisSize: MainAxisSize.min,

      children: [      curve: Curves.easeInOut,      curve: Curves.easeInOut,

        AnimatedBuilder(

          animation: _animation,    );    );

          builder: (context, child) {

            return Transform.scale(  }  }

              scale: _animation.value,

              child: Opacity(

                opacity: _animation.value,

                child: Column(  @override  @override

                  mainAxisSize: MainAxisSize.min,

                  children: [  void dispose() {  void dispose() {

                    _buildMenuItem(

                      icon: Icons.school,    _animationController.dispose();    _animationController.dispose();

                      label: 'Crear Curso',

                      onTap: () {},    super.dispose();    super.dispose();

                    ),

                    const SizedBox(height: 12),  }  }

                    _buildMenuItem(

                      icon: Icons.category,

                      label: 'Crear Categoría',

                      onTap: () {},  void _toggleMenu() {  void _toggleMenu() {

                    ),

                    const SizedBox(height: 12),    if (_isExpanded) {    if (_isExpanded) {

                    _buildMenuItem(

                      icon: Icons.assignment,      _animationController.reverse();      _animationController.reverse();

                      label: 'Crear Actividad',

                      onTap: () {},    } else {    } else {

                    ),

                    const SizedBox(height: 16),      _animationController.forward();      _animationController.forward();

                  ],

                ),    }    }

              ),

            );    setState(() {    setState(() {

          },

        ),      _isExpanded = !_isExpanded;      _isExpanded = !_isExpanded;

        FloatingActionButton(

          onPressed: _toggleMenu,    });    });

          backgroundColor: AppTheme.goldAccent,

          child: AnimatedRotation(  }  }

            turns: _isExpanded ? 0.125 : 0,

            duration: const Duration(milliseconds: 300),

            child: Icon(

              Icons.add,  @override  @override

              color: AppTheme.premiumBlack,

              size: 28,  Widget build(BuildContext context) {  Widget build(BuildContext context) {

            ),

          ),    return Column(    return Column(

        ),

      ],      mainAxisSize: MainAxisSize.min,      mainAxisSize: MainAxisSize.min,

    );

  }      children: [      children: [



  Widget _buildMenuItem({        // botones del menú        // botones del menú

    required IconData icon,

    required String label,        AnimatedBuilder(        AnimatedBuilder(

    required VoidCallback onTap,

  }) {          animation: _animation,          animation: _animation,

    return Container(

      margin: const EdgeInsets.only(right: 16),          builder: (context, child) {          builder: (context, child) {

      child: Row(

        mainAxisSize: MainAxisSize.min,            return Transform.scale(            return Transform.scale(

        children: [

          Container(              scale: _animation.value,              scale: _animation.value,

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            decoration: BoxDecoration(              child: Opacity(              child: Opacity(

              color: Theme.of(context).cardColor,

              borderRadius: BorderRadius.circular(20),                opacity: _animation.value,                opacity: _animation.value,

              border: Border.all(

                color: AppTheme.goldAccent.withOpacity(0.3),                child: Column(                child: Column(

                width: 1,

              ),                  mainAxisSize: MainAxisSize.min,                  mainAxisSize: MainAxisSize.min,

              boxShadow: [

                BoxShadow(                  children: [                  children: [

                  color: Colors.black.withOpacity(0.1),

                  blurRadius: 8,                    _buildMenuItem(                    _buildMenuItem(

                  offset: const Offset(0, 2),

                ),                      icon: Icons.school,                      icon: Icons.school,

              ],

            ),                      label: 'Crear Curso',                      label: 'Crear Curso',

            child: Text(

              label,                      onTap: () {},                      onTap: () {},

              style: TextStyle(

                fontSize: 14,                    ),                    ),

                fontWeight: FontWeight.w500,

                color: Theme.of(context).colorScheme.onSurface,                    const SizedBox(height: 12),                    const SizedBox(height: 12),

              ),

            ),                    _buildMenuItem(                    _buildMenuItem(

          ),

          const SizedBox(width: 8),                      icon: Icons.category,                      icon: Icons.category,

          FloatingActionButton.small(

            onPressed: onTap,                      label: 'Crear Categoría',                      label: 'Crear Categoría',

            backgroundColor: AppTheme.goldAccent.withOpacity(0.9),

            child: Icon(                      onTap: () {},                      onTap: () {},

              icon,

              color: AppTheme.premiumBlack,                    ),                    ),

              size: 20,

            ),                    const SizedBox(height: 12),                    const SizedBox(height: 12),

          ),

        ],                    _buildMenuItem(                    _buildMenuItem(

      ),

    );                      icon: Icons.assignment,                      icon: Icons.assignment,

  }

}                      label: 'Crear Actividad',                      label: 'Crear Actividad',

                      onTap: () {},                      onTap: () {},

                    ),                    ),

                    const SizedBox(height: 16),                    const SizedBox(height: 16),

                  ],                  ],

                ),                ),

              ),              ),

            );            );

          },          },

        ),        ),

        // botón principal        // botón principal

        FloatingActionButton(        FloatingActionButton(

          onPressed: _toggleMenu,          onPressed: _toggleMenu,

          backgroundColor: AppTheme.goldAccent,          backgroundColor: AppTheme.goldAccent,

          child: AnimatedRotation(          child: AnimatedRotation(

            turns: _isExpanded ? 0.125 : 0,            turns: _isExpanded ? 0.125 : 0,

            duration: const Duration(milliseconds: 300),            duration: const Duration(milliseconds: 300),

            child: Icon(            child: Icon(

              Icons.add,              Icons.add,

              color: AppTheme.premiumBlack,              color: AppTheme.premiumBlack,

              size: 28,              size: 28,

            ),            ),

          ),          ),

        ),        ),

      ],      ],

    );    );

  }  }



  Widget _buildMenuItem({  Widget _buildMenuItem({

    required IconData icon,    required IconData icon,

    required String label,    required String label,

    required VoidCallback onTap,    required VoidCallback onTap,

  }) {  }) {

    return Container(    return Container(

      margin: const EdgeInsets.only(right: 16),      margin: const EdgeInsets.only(right: 16),

      child: Row(      child: Row(

        mainAxisSize: MainAxisSize.min,        mainAxisSize: MainAxisSize.min,

        children: [        children: [

          Container(          Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            decoration: BoxDecoration(            decoration: BoxDecoration(

              color: Theme.of(context).cardColor,              color: Theme.of(context).cardColor,

              borderRadius: BorderRadius.circular(20),              borderRadius: BorderRadius.circular(20),

              border: Border.all(              border: Border.all(

                color: AppTheme.goldAccent.withOpacity(0.3),                color: AppTheme.goldAccent.withOpacity(0.3),

                width: 1,                width: 1,

              ),              ),

              boxShadow: [              boxShadow: [

                BoxShadow(                BoxShadow(

                  color: Colors.black.withOpacity(0.1),                  color: Colors.black.withOpacity(0.1),

                  blurRadius: 8,                  blurRadius: 8,

                  offset: const Offset(0, 2),                  offset: const Offset(0, 2),

                ),                ),

              ],              ],

            ),            ),

            child: Text(            child: Text(

              label,              label,

              style: TextStyle(              style: TextStyle(

                fontSize: 14,                fontSize: 14,

                fontWeight: FontWeight.w500,                fontWeight: FontWeight.w500,

                color: Theme.of(context).colorScheme.onSurface,                color: Theme.of(context).colorScheme.onSurface,

              ),              ),

            ),            ),

          ),          ),

          const SizedBox(width: 8),          const SizedBox(width: 8),

          FloatingActionButton.small(          FloatingActionButton.small(

            onPressed: onTap,            onPressed: onTap,

            backgroundColor: AppTheme.goldAccent.withOpacity(0.9),            backgroundColor: AppTheme.goldAccent.withOpacity(0.9),

            child: Icon(            child: Icon(

              icon,              icon,

              color: AppTheme.premiumBlack,              color: AppTheme.premiumBlack,

              size: 20,              size: 20,

            ),            ),

          ),          ),

        ],        ],

      ),      ),

    );    );

  }  }

}}
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // botón crear actividad
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 3.0,
            0.0,
          ),
          child: _buildFloatingButton(
            onPressed: () {
              animate();
              Get.snackbar(
                'Crear Actividad',
                'Funcionalidad próximamente disponible',
                backgroundColor: AppTheme.goldAccent,
                colorText: AppTheme.premiumBlack,
              );
            },
            icon: Icons.assignment,
            tooltip: 'Crear Actividad',
            backgroundColor: Colors.blue,
          ),
        ),
        // botón crear categoría
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 2.0,
            0.0,
          ),
          child: _buildFloatingButton(
            onPressed: () {
              animate();
              Get.snackbar(
                'Crear Categoría',
                'Funcionalidad próximamente disponible',
                backgroundColor: AppTheme.goldAccent,
                colorText: AppTheme.premiumBlack,
              );
            },
            icon: Icons.category,
            tooltip: 'Crear Categoría',
            backgroundColor: Colors.green,
          ),
        ),
        // botón crear curso
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value,
            0.0,
          ),
          child: _buildFloatingButton(
            onPressed: () {
              animate();
              Get.snackbar(
                'Crear Curso',
                'Funcionalidad próximamente disponible',
                backgroundColor: AppTheme.goldAccent,
                colorText: AppTheme.premiumBlack,
              );
            },
            icon: Icons.school,
            tooltip: 'Crear Curso',
            backgroundColor: Colors.purple,
          ),
        ),
        // botón principal
        FloatingActionButton(
          onPressed: animate,
          backgroundColor: AppTheme.goldAccent,
          elevation: 8,
          child: AnimatedBuilder(
            animation: _animationIcon,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationIcon.value * 0.785398, // 45 grados en radianes
                child: Icon(
                  Icons.add,
                  color: AppTheme.premiumBlack,
                  size: 28,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // tooltip con texto
          if (isMenuOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                tooltip,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          // botón flotante
          FloatingActionButton(
            mini: true,
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            elevation: 4,
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
