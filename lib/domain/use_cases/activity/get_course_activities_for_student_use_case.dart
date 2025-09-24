import '../../models/course_activity.dart';
import '../../repositories/course_activity_repository.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/group_repository.dart';

class GetCourseActivitiesForStudentParams {
  final String courseId;
  final String userId;
  GetCourseActivitiesForStudentParams(
      {required this.courseId, required this.userId});
}

/// Regla: las actividades se asignan a categorías; un estudiante ve actividades
/// de categorías en las que tiene membresía (a través de su grupo en esa categoría).
class GetCourseActivitiesForStudentUseCase {
  final CourseActivityRepository activityRepository;
  final MembershipRepository membershipRepository;
  final GroupRepository groupRepository;

  GetCourseActivitiesForStudentUseCase(
    this.activityRepository,
    this.membershipRepository,
    this.groupRepository,
  );

  Future<List<CourseActivity>> call(
      GetCourseActivitiesForStudentParams p) async {
    // 1) Traer todas las actividades del curso
    final all = await activityRepository.getActivitiesByCourse(p.courseId);
    if (all.isEmpty) return const [];

    // 2) Encontrar en cuáles categorías tiene membresía el usuario
    //    (membresías -> grupos -> category_id)
    //    Optimización simple: traer memberships por usuario, luego por cada membership traer group
    final myMemberships =
        await membershipRepository.getMembershipsByUserId(p.userId);
    if (myMemberships.isEmpty) return const [];
    final categoryIds = <String>{};
    for (final m in myMemberships) {
      final g = await groupRepository.getGroupById(m.groupId);
      if (g != null && g.courseId == p.courseId) {
        categoryIds.add(g.categoryId);
      }
    }
    if (categoryIds.isEmpty) return const [];

    // 3) Filtrar actividades a solo aquellas cuya category_id ∈ categoryIds
    final visible =
        all.where((a) => categoryIds.contains(a.categoryId)).toList();
    // orden simple: por fecha de vencimiento más cercana o por createdAt
    visible.sort((a, b) {
      final ad = a.dueDate ?? a.createdAt;
      final bd = b.dueDate ?? b.createdAt;
      return ad.compareTo(bd);
    });
    return visible;
  }
}
