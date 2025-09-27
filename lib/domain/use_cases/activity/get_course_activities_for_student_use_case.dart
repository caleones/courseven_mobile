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
    
    final all = await activityRepository.getActivitiesByCourse(p.courseId);
    if (all.isEmpty) return const [];

    
    
    
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

    
    final visible =
        all.where((a) => categoryIds.contains(a.categoryId)).toList();
    
    visible.sort((a, b) {
      final ad = a.dueDate ?? a.createdAt;
      final bd = b.dueDate ?? b.createdAt;
      return ad.compareTo(bd);
    });
    return visible;
  }
}
