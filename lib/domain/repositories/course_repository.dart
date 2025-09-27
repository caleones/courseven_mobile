import '../models/course.dart';


abstract class CourseRepository {
  
  Future<Course?> getCourseById(String courseId);

  
  Future<List<Course>> getCoursesByCategory(String categoryId);

  
  Future<List<Course>> getCoursesByTeacher(String teacherId);

  
  Future<Course> createCourse(Course course);

  
  Future<Course> updateCourse(Course course, {bool partial = true});

  
  Future<Course> setCourseActive(String courseId, bool active);

  
  Future<bool> deleteCourse(String courseId);

  
  Future<List<Course>> searchCoursesByTitle(String title);

  
  Future<Course?> getCourseByJoinCode(String joinCode);

  
  Future<List<Course>> getActiveCourses();

  
  Future<List<Course>> getCoursesPaginated({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? teacherId,
  });

  
  Future<List<Course>> getCoursesOrdered();

  
  Future<bool> updateCoursesOrder(List<String> courseIds);
}
