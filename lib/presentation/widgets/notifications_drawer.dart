import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../presentation/theme/app_theme.dart';

class NotificationsDrawer extends StatefulWidget {
  const NotificationsDrawer({super.key});

  @override
  State<NotificationsDrawer> createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends State<NotificationsDrawer> {
  String selectedFilter = 'Todas';
  final List<String> filters = ['Todas', 'No leídas', 'Cursos', 'Sistema'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // header del drawer
            _buildHeader(),
            // filtros
            _buildFilters(),
            // lista de notificaciones
            Expanded(
              child: _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            bool isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.goldAccent
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.goldAccent
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.premiumBlack
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final notifications = _getFilteredNotifications();

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando tengas notificaciones aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['isRead']
            ? Theme.of(context).cardColor
            : AppTheme.goldAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification['isRead']
              ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
              : AppTheme.goldAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            notification['isRead'] = true;
          });
          Get.snackbar(
            'Notificación',
            notification['title'],
            backgroundColor: AppTheme.goldAccent,
            colorText: AppTheme.premiumBlack,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icono
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: notification['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification['icon'],
                color: notification['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!notification['isRead'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: notification['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification['category'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: notification['color'],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        notification['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    final allNotifications = _getAllNotifications();

    switch (selectedFilter) {
      case 'No leídas':
        return allNotifications.where((n) => !n['isRead']).toList();
      case 'Cursos':
        return allNotifications.where((n) => n['category'] == 'Curso').toList();
      case 'Sistema':
        return allNotifications
            .where((n) => n['category'] == 'Sistema')
            .toList();
      default:
        return allNotifications;
    }
  }

  List<Map<String, dynamic>> _getAllNotifications() {
    return [
      {
        'title': 'Nueva clase disponible',
        'body': 'La clase "State Management en Flutter" ya está disponible',
        'category': 'Curso',
        'time': 'Hace 2 horas',
        'icon': Icons.play_circle,
        'color': Colors.blue,
        'isRead': false,
      },
      {
        'title': 'Tarea entregada',
        'body': 'Tu tarea de "Bases de Datos" ha sido entregada exitosamente',
        'category': 'Curso',
        'time': 'Hace 4 horas',
        'icon': Icons.assignment_turned_in,
        'color': Colors.green,
        'isRead': false,
      },
      {
        'title': 'Recordatorio de examen',
        'body': 'Tu examen de "Arquitectura de Software" es mañana a las 10:00',
        'category': 'Curso',
        'time': 'Hace 6 horas',
        'icon': Icons.schedule,
        'color': Colors.orange,
        'isRead': true,
      },
      {
        'title': 'Nuevo certificado',
        'body': 'Has obtenido el certificado de "Flutter para Principiantes"',
        'category': 'Sistema',
        'time': 'Hace 1 día',
        'icon': Icons.workspace_premium,
        'color': Colors.purple,
        'isRead': false,
      },
      {
        'title': 'Actualización disponible',
        'body': 'Una nueva versión de la aplicación está disponible',
        'category': 'Sistema',
        'time': 'Hace 2 días',
        'icon': Icons.system_update,
        'color': Colors.teal,
        'isRead': true,
      },
      {
        'title': 'Calificación recibida',
        'body': 'Has recibido tu calificación para "UX/UI Design Patterns"',
        'category': 'Curso',
        'time': 'Hace 2 días',
        'icon': Icons.grade,
        'color': Colors.pink,
        'isRead': true,
      },
      {
        'title': 'Nuevo anuncio',
        'body': 'El profesor ha publicado un anuncio en "Machine Learning"',
        'category': 'Curso',
        'time': 'Hace 3 días',
        'icon': Icons.announcement,
        'color': Colors.amber,
        'isRead': true,
      },
      {
        'title': 'Curso completado',
        'body': 'Felicidades! Has completado "Blockchain y Criptomonedas"',
        'category': 'Sistema',
        'time': 'Hace 1 semana',
        'icon': Icons.emoji_events,
        'color': Colors.red,
        'isRead': true,
      },
    ];
  }
}
