import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_navigation_dock.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String selectedFilter = 'Todas';
  final List<String> filters = ['Todas', 'No leídas', 'Cursos', 'Sistema'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Notificaciones',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationDock(
        currentIndex: 2,
        hasNewNotifications: false,
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
                              .withOpacity(0.25),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.goldAccent.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
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
    final isUnread = notification['isRead'] == false;
    final outline = Theme.of(context).colorScheme.outline.withOpacity(0.1);
    final Color color = (notification['color'] is Color)
        ? notification['color'] as Color
        : AppTheme.goldAccent;
    final IconData icon = (notification['icon'] is IconData)
        ? notification['icon'] as IconData
        : Icons.notifications;
    final String title = (notification['title'] ?? '').toString();
    final String body = (notification['body'] ?? '').toString();
    final String category = (notification['category'] ?? '').toString();
    final String time = (notification['time'] ?? '').toString();

    final borderRadius = BorderRadius.circular(12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: () {
                setState(() {
                  notification['isRead'] = true;
                });
                Get.snackbar(
                  'Notificación',
                  title.isNotEmpty ? title : 'Detalle',
                  backgroundColor: AppTheme.goldAccent,
                  colorText: AppTheme.premiumBlack,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(color: outline, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.goldAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
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
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                time,
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
            ),
          ),
          
          if (isUnread)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 3,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 1.0),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: borderRadius.topLeft,
                      bottomLeft: borderRadius.bottomLeft,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
