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

  /// Valida límite de cursos y crea el curso
  /// Lanza excepción con mensaje de negocio cuando no se puede crear
  Future<Course> call(CreateCourseParams params) async {
    // 1) Validar límite
    final existing = await _repository.getCoursesByTeacher(params.teacherId);
    if (existing.length >= maxCoursesPerTeacher) {
      throw Exception(
          'Has alcanzado el límite de $maxCoursesPerTeacher cursos como profesor.');
    }

    // 2) Generar join_code único y sencillo (6-8 chars alfanuméricos)
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = now.toRadixString(36).toUpperCase();
    final joinCode = base.substring(base.length - 6);

    // 3) Construir entidad Course (id vacío para que DB lo asigne)
    final newCourse = Course(
      id: '',
      name: params.name.trim(),
      description: params.description.trim(),
      joinCode: joinCode,
      teacherId: params.teacherId,
      createdAt: DateTime.now(),
      isActive: true,
    );

    // 4) Persistir
    return await _repository.createCourse(newCourse);
  }
}
