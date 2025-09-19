import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/theme_toggle_widget.dart';
import '../../widgets/notifications_drawer.dart';
import '../../widgets/bottom_navigation_dock.dart';
import '../../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = Get.find<AuthController>();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildHomeContent()
            : _buildPlaceholderContent(),
      ),
      bottomNavigationBar: const BottomNavigationDock(currentIndex: 0),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header con bienvenida y notificaciones
          _buildWelcomeCard(),
          const SizedBox(height: 24),

          // sección mi enseñanza
          _buildTeachingSection(),
          const SizedBox(height: 24),

          // sección mi aprendizaje
          _buildLearningSection(),
          const SizedBox(height: 24),

          // sección información
          _buildInformationSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldAccent.withOpacity(0.1),
            AppTheme.lightGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // fila superior con toggle y notificaciones
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const ThemeToggleWidget(),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.goldAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => _showNotificationsDrawer(),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.goldAccent,
                    size: 24,
                  ),
                ),
              ),
            ],
          ), // --------------------
          const SizedBox(height: 16),
          // fila con ícono de perfil a la izquierda
          Row(
            children: [
              // ícono de perfil del usuario
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.goldAccent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: AppTheme.goldAccent,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi enseñanza',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // 3 cursos que enseño
        _buildTeachingCourseCard(
          title: 'Desarrollo Móvil con Flutter',
          subtitle: 'Programación • 45 estudiantes',
          color: Colors.blue,
          icon: Icons.phone_android,
        ),
        const SizedBox(height: 12),
        _buildTeachingCourseCard(
          title: 'Bases de Datos Avanzadas',
          subtitle: 'Base de Datos • 32 estudiantes',
          color: Colors.green,
          icon: Icons.storage,
        ),
        const SizedBox(height: 12),
        _buildTeachingCourseCard(
          title: 'Arquitectura de Software',
          subtitle: 'Ingeniería • 28 estudiantes',
          color: Colors.purple,
          icon: Icons.architecture,
        ),
      ],
    );
  }

  Widget _buildLearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi aprendizaje',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // 5 cursos que estoy tomando
        _buildCourseCard(
          title: 'Machine Learning Fundamentals',
          subtitle: 'IA • Dr. Rodriguez',
          progress: 0.40,
          color: Colors.orange,
          icon: Icons.psychology,
        ),
        const SizedBox(height: 12),
        _buildCourseCard(
          title: 'Blockchain y Criptomonedas',
          subtitle: 'Tecnología • Prof. Martinez',
          progress: 0.65,
          color: Colors.amber,
          icon: Icons.currency_bitcoin,
        ),
        const SizedBox(height: 12),
        _buildCourseCard(
          title: 'UX/UI Design Patterns',
          subtitle: 'Diseño • Dra. Silva',
          progress: 0.30,
          color: Colors.pink,
          icon: Icons.design_services,
        ),
        const SizedBox(height: 12),
        _buildCourseCard(
          title: 'Cloud Computing AWS',
          subtitle: 'Infraestructura • Prof. Chen',
          progress: 0.55,
          color: Colors.teal,
          icon: Icons.cloud,
        ),
        const SizedBox(height: 12),
        _buildCourseCard(
          title: 'Ciberseguridad Avanzada',
          subtitle: 'Seguridad • Dr. Johnson',
          progress: 0.20,
          color: Colors.red,
          icon: Icons.security,
        ),
        const SizedBox(height: 12),
        // tile para ver todos los cursos
        _buildViewAllCoursesCard(),
      ],
    );
  }

  Widget _buildInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // tile de actividades
        _buildInfoTile(
          title: 'Actividades',
          subtitle: 'Ver todas las actividades',
          icon: Icons.assignment,
          color: Colors.indigo,
          onTap: () {
            Get.snackbar(
              'Actividades',
              'Funcionalidad en desarrollo',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
        const SizedBox(height: 12),
        // tile de anuncios
        _buildInfoTile(
          title: 'Anuncios',
          subtitle: 'Últimas noticias y actualizaciones',
          icon: Icons.campaign,
          color: Colors.cyan,
          onTap: () {
            Get.snackbar(
              'Anuncios',
              'Funcionalidad en desarrollo',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          // icono del curso
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // info del curso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                // barra de progreso
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // flecha
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  // método para tarjetas de cursos que enseño (sin barra de progreso)
  Widget _buildTeachingCourseCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          // icono del curso
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // info del curso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // flecha
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  // método para el tile "Ver todos los cursos"
  Widget _buildViewAllCoursesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldAccent.withOpacity(0.2),
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
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Ver todos los cursos',
            'Funcionalidad próximamente disponible',
            backgroundColor: AppTheme.goldAccent,
            colorText: AppTheme.premiumBlack,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // icono
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.library_books,
                color: AppTheme.goldAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // texto
            Expanded(
              child: Text(
                'Ver todos los cursos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldAccent,
                ),
              ),
            ),
            // flecha
            Icon(
              Icons.chevron_right,
              color: AppTheme.goldAccent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
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

  // método para mostrar el drawer de notificaciones
  void _showNotificationsDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: const NotificationsDrawer(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Get.snackbar(
          'Crear Contenido',
          'Funcionalidad próximamente disponible',
          backgroundColor: AppTheme.goldAccent,
          colorText: AppTheme.premiumBlack,
        );
      },
      backgroundColor: AppTheme.goldAccent,
      child: Icon(
        Icons.add,
        color: AppTheme.premiumBlack,
        size: 28,
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Próximamente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta funcionalidad estará disponible pronto',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
