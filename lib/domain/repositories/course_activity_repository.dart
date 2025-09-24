import '../models/course_activity.dart';

/// Repositorio para actividades de curso (tareas) asignadas a categorías
abstract class CourseActivityRepository {
  Future<CourseActivity?> getActivityById(String activityId);
  Future<List<CourseActivity>> getActivitiesByCourse(String courseId);
  Future<List<CourseActivity>> getActivitiesByCategory(String categoryId);
  Future<CourseActivity> createActivity(CourseActivity activity);
  Future<CourseActivity> updateActivity(CourseActivity activity);
  Future<bool> deleteActivity(
      String activityId); // soft delete (is_active=false)
}
