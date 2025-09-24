import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/bottom_navigation_dock.dart';
import '../../theme/app_theme.dart';
import '../create/create_options_page.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/enrollment_controller.dart';
import '../../../core/config/app_routes.dart';
import '../../../domain/use_cases/course/create_course_use_case.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = Get.find<AuthController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final CourseController courseController = Get.find<CourseController>();
  final EnrollmentController enrollmentController =
      Get.find<EnrollmentController>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Intento proactivo de cargar cursos del profesor
    courseController.loadMyTeachingCourses();
    // y mis inscripciones
    enrollmentController.loadMyEnrollments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildHomeContent()
            : _buildPlaceholderContent(),
      ),
      bottomNavigationBar: const BottomNavigationDock(
        currentIndex: 0,
        hasNewNotifications: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldAccent,
        onPressed: () {
          Get.to(() => const CreateOptionsPage());
        },
        child: Icon(Icons.add, color: AppTheme.premiumBlack),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildTeachingSection(),
          const SizedBox(height: 24),
          _buildLearningSection(),
          const SizedBox(height: 24),
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
        // Usar superficie sólida en ambos temas
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  authController.currentUser?.fullName.isNotEmpty == true
                      ? authController.currentUser!.fullName
                      : (authController.currentUser?.firstName ?? ''),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  authController.currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingSection() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Obx(() {
      final all = courseController.teacherCourses;
      final loading = courseController.isLoading.value;
      final active = all.where((c) => c.isActive).toList();
      final activeCount = active.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi enseñanza',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount/${CreateCourseUseCase.maxCoursesPerTeacher} activos',
                  style: TextStyle(
                    color: AppTheme.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (active.isEmpty)
              _buildEmptyTeachingState()
            else ...[
              // Activos primero
              ...active.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(AppRoutes.courseDetail, arguments: {
                          'courseId': c.id,
                          'asTeacher': true,
                        });
                      },
                      child: _buildTeachingCourseCard(
                        title: c.name,
                        subtitle: 'Código: ${c.joinCode}',
                        color: Colors.blue,
                        icon: Icons.class_,
                      ),
                    ),
                  )),
              // Regla de negocio: NO mostrar cursos inactivos en home.
            ],
          ],
          const SizedBox(height: 8),
          _buildTeacherAllCoursesTile(
              all.length, all.where((c) => !c.isActive).length),
        ],
      );
    });
  }

  Widget _buildTeacherAllCoursesTile(int total, int inactiveCount) {
    return InkWell(
      onTap: () {
        // Navegar a la pantalla unificada con modo docente
        Get.toNamed(AppRoutes.allCourses, arguments: {'mode': 'teaching'});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.library_books,
                  color: AppTheme.successGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ver todos',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    '$total en total • $inactiveCount inactivos',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTeachingState() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Simple emoji/placeholder for tumbleweed/cobweb
          Text('🕸️', style: TextStyle(fontSize: 36, color: onSurface)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no estás enseñando',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea tu primer curso con el botón +',
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSection() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Obx(() {
      final list = enrollmentController.myEnrollments;
      final loading = enrollmentController.isLoading.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi aprendizaje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.joinCourse),
                icon: const Icon(Icons.login),
                label: const Text('Unirme a un curso'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (list.isEmpty)
            _buildEmptyLearningState()
          else
            ...list.map((e) {
              final title = enrollmentController.getCourseTitle(e.courseId);
              final teacher =
                  enrollmentController.getCourseTeacherName(e.courseId);
              final course = courseController.coursesCache[e.courseId];
              final isInactive = course != null && !course.isActive;
              final subtitle = [
                if (teacher.isNotEmpty) teacher,
                'Inscrito el ${e.enrolledAt.toLocal().toString().substring(0, 16)}',
              ].join(' • ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLearningCourseTile(
                  title: title,
                  subtitle: subtitle,
                  color: isInactive ? AppTheme.dangerRed : Colors.orange,
                  icon: Icons.school,
                  onTap: () {
                    Get.toNamed(AppRoutes.courseDetail,
                        arguments: {'courseId': e.courseId});
                  },
                  trailingPill: isInactive
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: AppTheme.dangerRed, width: 1),
                          ),
                          child: const Text(
                            'INACTIVO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          const SizedBox(height: 12),
          _buildViewAllCoursesCard(),
        ],
      );
    });
  }

  Widget _buildEmptyLearningState() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text('🧭', style: TextStyle(fontSize: 36, color: onSurface)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no te has unido a cursos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Usa “Unirme a un curso” para ingresar un código de ingreso',
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  // Removed old _buildCourseCard with progress; using _buildLearningCourseTile instead.

  Widget _buildLearningCourseTile({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailingPill,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (trailingPill != null) trailingPill,
                    ],
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
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllCoursesCard() {
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
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.allCourses, arguments: {'mode': 'learning'});
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.library_books,
                  color: AppTheme.goldAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Ver todos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldAccent,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.goldAccent, size: 20),
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
              child: Icon(icon, color: color, size: 22),
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
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                size: 20),
          ],
        ),
      ),
    );
  }

  // (Eliminado) Fabs verticales; ahora se navega a CreateOptionsPage con el +

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

// Widget interno: FAB expandible horizontal con cierre al tocar fuera
// (Eliminado) Expandable FAB y pills: reemplazado por 3 FABs verticales
