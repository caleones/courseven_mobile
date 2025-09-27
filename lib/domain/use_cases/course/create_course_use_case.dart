import '../../models/course.dart';
import '../../repositories/course_repository.dart';

class CreateCourseParams {
  final String name;
  final String description;
  final String teacherId;

  const CreateCourseParams({
    required this.name,
    required this.description,
    required this.teacherId,
  });
}

class CreateCourseUseCase {
  final CourseRepository _repository;
  static const int maxCoursesPerTeacher = 3;

  CreateCourseUseCase(this._repository);

  
  
  Future<Course> call(CreateCourseParams params) async {
    
    final existing = await _repository.getCoursesByTeacher(params.teacherId);
    if (existing.length >= maxCoursesPerTeacher) {
      throw Exception(
          'Has alcanzado el límite de $maxCoursesPerTeacher cursos como profesor.');
    }

    
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = now.toRadixString(36).toUpperCase();
    final joinCode = base.substring(base.length - 6);

    
    final newCourse = Course(
      id: '',
      name: params.name.trim(),
      description: params.description.trim(),
      joinCode: joinCode,
      teacherId: params.teacherId,
      createdAt: DateTime.now(),
      isActive: true,
    );

    
    return await _repository.createCourse(newCourse);
  }
}
