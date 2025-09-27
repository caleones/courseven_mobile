import '../models/course_activity.dart';


abstract class CourseActivityRepository {
  Future<CourseActivity?> getActivityById(String activityId);
  Future<List<CourseActivity>> getActivitiesByCourse(String courseId);
  Future<List<CourseActivity>> getActivitiesByCategory(String categoryId);
  Future<CourseActivity> createActivity(CourseActivity activity);
  Future<CourseActivity> updateActivity(CourseActivity activity);
  Future<bool> deleteActivity(
      String activityId); 
}
