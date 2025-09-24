import 'package:get/get.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/email_verification_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/create/course_create_page.dart';
import '../../presentation/pages/create/category_create_page.dart';
import '../../presentation/pages/create/group_create_page.dart';
import '../../presentation/pages/create/join_course_page.dart';
import '../../presentation/pages/learning/all_courses_page.dart';
import '../../presentation/pages/learning/course_detail_page.dart';
import '../../presentation/pages/learning/course_categories_page.dart';
import '../../presentation/pages/learning/course_groups_page.dart';
import '../../presentation/pages/learning/category_groups_page.dart';
import '../../presentation/pages/learning/course_activities_page.dart';
import '../../presentation/pages/create/activity_create_page.dart';
import '../../presentation/pages/edit/course_edit_page.dart';
// NEW detail & edit pages
import '../../presentation/pages/learning/activity_detail_page.dart';
import '../../presentation/pages/edit/activity_edit_page.dart';
import '../../presentation/pages/learning/category_detail_page.dart';
import '../../presentation/pages/edit/category_edit_page.dart';
import '../../presentation/pages/learning/course_students_page.dart';
import '../../presentation/pages/learning/category_activities_page.dart';
import '../../presentation/pages/peer_review/peer_review_list_page.dart';
import '../../presentation/pages/peer_review/peer_review_evaluate_page.dart';
import '../../presentation/pages/peer_review/group_peer_review_summary_page.dart';
import '../../presentation/pages/peer_review/course_peer_review_summary_page.dart';

// todas las rutas de navegación de la app
class AppRoutes {
  static const String login = '/login';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String courseCreate = '/course-create';
  static const String categoryCreate = '/category-create';
  static const String groupCreate = '/group-create';
  static const String joinCourse = '/join-course';
  static const String allCourses = '/all-courses';
  static const String courseDetail = '/course-detail';
  static const String courseCategories = '/course-categories';
  static const String courseGroups = '/course-groups';
  static const String categoryGroups = '/category-groups';
  static const String courseActivities = '/course-activities';
  static const String activityCreate = '/activity-create';
  static const String courseEdit = '/course-edit';
  static const String activityDetail = '/activity-detail';
  static const String activityEdit = '/activity-edit';
  static const String categoryDetail = '/category-detail';
  static const String categoryEdit = '/category-edit';
  static const String courseStudents = '/course-students';
  static const String categoryActivities = '/category-activities';
  static const String peerReviewList = '/peer-review-list';
  static const String peerReviewEvaluate = '/peer-review-evaluate';
  static const String peerReviewGroupSummary = '/peer-review-group-summary';
  static const String peerReviewCourseSummary = '/peer-review-course-summary';

  static List<GetPage> routes = [
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: emailVerification, page: () => const EmailVerificationPage()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: courseCreate, page: () => const CourseCreatePage()),
    GetPage(name: categoryCreate, page: () => const CategoryCreatePage()),
    GetPage(name: groupCreate, page: () => const GroupCreatePage()),
    GetPage(name: joinCourse, page: () => const JoinCoursePage()),
    GetPage(name: allCourses, page: () => const AllCoursesPage()),
    GetPage(name: courseDetail, page: () => const CourseDetailPage()),
    GetPage(name: courseCategories, page: () => const CourseCategoriesPage()),
    GetPage(name: courseGroups, page: () => const CourseGroupsPage()),
    GetPage(name: categoryGroups, page: () => const CategoryGroupsPage()),
    GetPage(name: courseActivities, page: () => const CourseActivitiesPage()),
    GetPage(name: activityCreate, page: () => const ActivityCreatePage()),
    GetPage(name: courseEdit, page: () => const CourseEditPage()),
    GetPage(name: activityDetail, page: () => const ActivityDetailPage()),
    GetPage(name: activityEdit, page: () => const ActivityEditPage()),
    GetPage(name: categoryDetail, page: () => const CategoryDetailPage()),
    GetPage(name: categoryEdit, page: () => const CategoryEditPage()),
    // Students listing for a course
    GetPage(name: courseStudents, page: () => const CourseStudentsPage()),
    GetPage(
        name: categoryActivities, page: () => const CategoryActivitiesPage()),
    // Peer Review
    GetPage(name: peerReviewList, page: () => const PeerReviewListPage()),
    GetPage(
        name: peerReviewEvaluate, page: () => const PeerReviewEvaluatePage()),
    GetPage(
        name: peerReviewGroupSummary,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return GroupPeerReviewSummaryPage(
              activityId: args['activityId'] ?? '');
        }),
    GetPage(
        name: peerReviewCourseSummary,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return CoursePeerReviewSummaryPage(
            courseId: args['courseId'] ?? '',
            activityIds:
                (args['activityIds'] as List?)?.cast<String>() ?? const [],
          );
        }),
  ];
}
