import '../models/activity.dart';

/// Repositorio abstracto para manejo de actividades
abstract class ActivityRepository {
  /// Obtener actividad por ID
  Future<Activity?> getActivityById(String activityId);

  /// Obtener actividades por usuario
  Future<List<Activity>> getActivitiesByUserId(String userId);

  /// Obtener actividades por tipo de entidad
  Future<List<Activity>> getActivitiesByEntityType(String entityType);

  /// Obtener actividades por entidad específica
  Future<List<Activity>> getActivitiesByEntity(
      String entityType, String entityId);

  /// Crear nueva actividad
  Future<Activity> createActivity(Activity activity);

  /// Eliminar actividad
  Future<bool> deleteActivity(String activityId);

  /// Obtener actividades recientes
  Future<List<Activity>> getRecentActivities({
    int limit = 10,
  });

  /// Obtener actividades paginadas
  Future<List<Activity>> getActivitiesPaginated({
    int page = 1,
    int limit = 10,
    String? userId,
    String? entityType,
  });

  /// Obtener actividades por rango de fechas
  Future<List<Activity>> getActivitiesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
