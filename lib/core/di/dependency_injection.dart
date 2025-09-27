import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/roble_service.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/theme_controller.dart';
import '../../domain/repositories/course_repository.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/repositories/group_repository.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../../data/repositories/enrollment_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../data/repositories/membership_repository_impl.dart';
import '../../domain/repositories/course_activity_repository.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../presentation/controllers/course_controller.dart';
import '../../domain/use_cases/course/create_course_use_case.dart';
import '../../domain/use_cases/category/create_category_use_case.dart';
import '../../domain/use_cases/group/create_group_use_case.dart';
import '../../presentation/controllers/category_controller.dart';
import '../../presentation/controllers/group_controller.dart';
import '../../domain/use_cases/enrollment/enroll_to_course_use_case.dart';
import '../../domain/use_cases/enrollment/get_my_enrollments_use_case.dart';
import '../../presentation/controllers/enrollment_controller.dart';
import '../../presentation/controllers/membership_controller.dart';
import '../../domain/use_cases/membership/join_group_use_case.dart';
import '../../presentation/controllers/activity_controller.dart';
import '../../domain/use_cases/activity/get_course_activities_for_student_use_case.dart';
import '../utils/refresh_manager.dart';
import '../utils/app_event_bus.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../../data/repositories/assessment_repository_impl.dart';
import '../../presentation/controllers/peer_review_controller.dart';


class DependencyInjection {
  
  static Future<void> init() async {
    
    _setupHttpClient();

    
    _setupServices();

    
    _setupControllers();
  }

  
  static void _setupHttpClient() {
    final dio = Dio();

    
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
        ),
      );
    }

    
    Get.put<Dio>(dio, permanent: true);
  }

  
  static void _setupServices() {
    
    Get.put<RobleService>(
      RobleService(),
      permanent: true,
    );

    
    Get.put<RefreshManager>(RefreshManager(), permanent: true);
    Get.put<AppEventBus>(AppEventBus(), permanent: true);
  }

  
  static void _setupControllers() {
    
    Get.put<ThemeController>(
      ThemeController(),
      permanent: true,
    );

    
    Get.put<AuthController>(
      AuthController(Get.find<RobleService>()),
      permanent: true,
    );

    
    Get.lazyPut<CourseRepository>(
      () => CourseRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    Get.lazyPut<CategoryRepository>(
      () => CategoryRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    Get.lazyPut<GroupRepository>(
      () => GroupRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    Get.lazyPut<EnrollmentRepository>(
      () => EnrollmentRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    Get.lazyPut<UserRepository>(
      () => UserRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    Get.lazyPut<MembershipRepository>(
      () => MembershipRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    Get.lazyPut<CourseActivityRepository>(
      () => CourseActivityRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    
    Get.lazyPut<AssessmentRepository>(
      () => AssessmentRepositoryImpl(
        Get.find<RobleService>(),
        getAccessToken: () => Get.find<AuthController>().getAccessToken(),
      ),
      fenix: true,
    );

    
    Get.lazyPut<CourseController>(
      () => CourseController(
        CreateCourseUseCase(Get.find<CourseRepository>()),
        Get.find<CourseRepository>(),
      ),
      fenix: true,
    );

    
    Get.lazyPut<CategoryController>(
      () => CategoryController(
        Get.find<CategoryRepository>(),
        CreateCategoryUseCase(Get.find<CategoryRepository>()),
      ),
      fenix: true,
    );

    
    Get.lazyPut<GroupController>(
      () => GroupController(
        Get.find<GroupRepository>(),
        CreateGroupUseCase(Get.find<GroupRepository>()),
      ),
      fenix: true,
    );

    
    Get.lazyPut<EnrollmentController>(
      () => EnrollmentController(
        EnrollToCourseUseCase(
          Get.find<EnrollmentRepository>(),
          Get.find<CourseRepository>(),
        ),
        GetMyEnrollmentsUseCase(Get.find<EnrollmentRepository>()),
        Get.find<CourseRepository>(),
        Get.find<UserRepository>(),
      ),
      fenix: true,
    );

    
    Get.lazyPut<MembershipController>(
      () => MembershipController(
        JoinGroupUseCase(
          Get.find<MembershipRepository>(),
          Get.find<GroupRepository>(),
          Get.find<CategoryRepository>(),
        ),
        Get.find<MembershipRepository>(),
      ),
      fenix: true,
    );

    
    Get.lazyPut<ActivityController>(
      () => ActivityController(
        GetCourseActivitiesForStudentUseCase(
          Get.find<CourseActivityRepository>(),
          Get.find<MembershipRepository>(),
          Get.find<GroupRepository>(),
        ),
        Get.find<GroupRepository>(),
        Get.find<MembershipRepository>(),
        Get.find<CourseActivityRepository>(),
      ),
      fenix: true,
    );

    
    Get.lazyPut<PeerReviewController>(
      () => PeerReviewController(
        Get.find<AssessmentRepository>(),
        Get.find<MembershipRepository>(),
        Get.find<GroupRepository>(),
      ),
      fenix: true,
    );
  }

  
  static void dispose() {
    Get.deleteAll();
  }
}
