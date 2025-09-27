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

import '../../presentation/pages/learning/activity_detail_page.dart';
import '../../presentation/pages/edit/activity_edit_page.dart';
import '../../presentation/pages/learning/category_detail_page.dart';
import '../../presentation/pages/edit/category_edit_page.dart';
import '../../presentation/pages/learning/group_detail_page.dart';
import '../../presentation/pages/edit/group_edit_page.dart';
import '../../presentation/pages/learning/course_students_page.dart';
import '../../presentation/pages/learning/student_detail_page.dart';
import '../../presentation/pages/learning/category_activities_page.dart';
import '../../presentation/pages/peer_review/peer_review_list_page.dart';
import '../../presentation/pages/peer_review/peer_review_evaluate_page.dart';
import '../../presentation/pages/peer_review/group_peer_review_summary_page.dart';
import '../../presentation/pages/peer_review/course_peer_review_summary_page.dart';
import '../../presentation/pages/peer_review/activity_peer_review_results_page.dart';
import '../../presentation/pages/peer_review/group_peer_review_results_page.dart';
import '../../presentation/pages/peer_review/student_peer_review_results_page.dart';
import '../../presentation/pages/peer_review/assessment_detail_page.dart';
import '../../presentation/pages/peer_review/student_own_peer_review_results_page.dart';
import '../../presentation/pages/peer_review/student_course_peer_results_page.dart';

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
  static const String groupDetail = '/group-detail';
  static const String groupEdit = '/group-edit';
  static const String courseStudents = '/course-students';
  static const String studentDetail = '/student-detail';
  static const String categoryActivities = '/category-activities';
  static const String peerReviewList = '/peer-review-list';
  static const String peerReviewEvaluate = '/peer-review-evaluate';
  static const String peerReviewGroupSummary = '/peer-review-group-summary';
  static const String peerReviewCourseSummary = '/peer-review-course-summary';

  static const String activityPeerReviewResults =
      '/activity-peer-review-results';
  static const String groupPeerReviewResults = '/group-peer-review-results';
  static const String studentPeerReviewResults = '/student-peer-review-results';
  static const String assessmentDetail = '/assessment-detail';
  static const String studentPeerReviewOwnResults =
      '/student-peer-review-own-results';
  static const String studentCoursePeerResults = '/student-course-peer-results';

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
    GetPage(name: groupDetail, page: () => const GroupDetailPage()),
    GetPage(name: groupEdit, page: () => const GroupEditPage()),
    GetPage(name: courseStudents, page: () => const CourseStudentsPage()),
    GetPage(
        name: studentDetail,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return StudentDetailPage(
            courseId: args['courseId'] ?? '',
            studentId: args['studentId'] ?? '',
          );
        }),
    GetPage(
        name: categoryActivities, page: () => const CategoryActivitiesPage()),
    GetPage(name: peerReviewList, page: () => const PeerReviewListPage()),
    GetPage(
        name: peerReviewEvaluate, page: () => const PeerReviewEvaluatePage()),
    GetPage(
        name: peerReviewGroupSummary,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return GroupCoursePeerResultsPage(
            courseId: args['courseId'] ?? '',
            groupId: args['groupId'] ?? '',
            activityIds:
                (args['activityIds'] as List?)?.cast<String>() ?? const [],
            groupName: args['groupName'] as String?,
          );
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
    GetPage(
        name: activityPeerReviewResults,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return ActivityPeerReviewResultsPage(
            courseId: args['courseId'] ?? '',
            activityId: args['activityId'] ?? '',
          );
        }),
    GetPage(
        name: groupPeerReviewResults,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return GroupPeerReviewResultsPage(
            courseId: args['courseId'] ?? '',
            activityId: args['activityId'] ?? '',
            groupId: args['groupId'] ?? '',
          );
        }),
    GetPage(
        name: studentPeerReviewResults,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return StudentPeerReviewResultsPage(
            courseId: args['courseId'] ?? '',
            activityId: args['activityId'] ?? '',
            groupId: args['groupId'] ?? '',
            studentId: args['studentId'] ?? '',
          );
        }),
    GetPage(
        name: assessmentDetail,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return AssessmentDetailPage(
            courseId: args['courseId'] ?? '',
            activityId: args['activityId'] ?? '',
            assessmentId: args['assessmentId'] ?? '',
          );
        }),
    GetPage(
        name: studentPeerReviewOwnResults,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return StudentOwnPeerReviewResultsPage(
            courseId: args['courseId'] ?? '',
            activityId: args['activityId'] ?? '',
          );
        }),
    GetPage(
        name: studentCoursePeerResults,
        page: () {
          final args = Get.arguments as Map? ?? {};
          return StudentCoursePeerResultsPage(
            courseId: args['courseId'] ?? '',
            studentId: args['studentId'] ?? '',
          );
        }),
  ];
}
