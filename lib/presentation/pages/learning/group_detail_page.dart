import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/config/app_routes.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/membership_controller.dart';
import '../../controllers/course_controller.dart';
import '../../controllers/activity_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/course/course_ui_components.dart';
import '../../widgets/inactive_gate.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/membership.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../../widgets/revalidation_mixin.dart';
import '../../../core/utils/refresh_manager.dart';
import '../../../core/utils/app_event_bus.dart';


class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with RevalidationMixin {
  final groupController = Get.find<GroupController>();
  final categoryController = Get.find<CategoryController>();
  final membershipController = Get.find<MembershipController>();
  final courseController = Get.find<CourseController>();
  final activityController = Get.find<ActivityController>();
  final userRepository = Get.find<UserRepository>();
  final membershipRepository = Get.find<MembershipRepository>();

  late final String courseId;
  late final String groupId;
  Group? _group;
  List<Membership> _members = const [];
  final Map<String, String> _userNameCache = {};
  bool _loadingMembers = false;
  bool _requestedCourseLoad = false;
  late final AppEventBus _bus;
  StreamSubscription<Object>? _sub;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    courseId = args?['courseId'] ?? '';
    groupId = args?['groupId'] ?? '';
    _bus = Get.find<AppEventBus>();
    _sub = _bus.stream.listen((event) async {
      if (event is MembershipJoinedEvent && event.courseId == courseId) {
        
        await revalidate(force: true);
      }
    });
    _primeData();
  }

  Future<void> _primeData() async {
    if (courseId.isNotEmpty &&
        courseController.coursesCache[courseId] == null &&
        !_requestedCourseLoad) {
      _requestedCourseLoad = true;
      courseController.getCourseById(courseId);
    }
    
    if (groupController.groupsByCourse[courseId] == null) {
      await groupController.loadByCourse(courseId);
    }
    final groups = groupController.groupsByCourse[courseId] ?? const [];
    _group = groups.firstWhereOrNull((g) => g.id == groupId);
    if (_group != null) {
      _loadMembers();
      
      membershipController.preloadMembershipsForGroups([groupId]);
      membershipController.preloadMemberCountsForGroups([groupId]);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final memberships =
          await membershipRepository.getMembershipsByGroupId(groupId);
      _members = memberships.where((m) => m.isActiveMembership).toList();
      
      for (final m in _members) {
        if (_userNameCache.containsKey(m.userId)) continue;
        final u = await userRepository.getUserById(m.userId);
        if (u != null) {
          _userNameCache[m.userId] =
              u.fullName.isNotEmpty ? u.fullName : u.email;
        }
      }
    } catch (_) {
      
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Duration? get pollingInterval => const Duration(seconds: 45);

  @override
  Future<void> revalidate({bool force = false}) async {
    if (groupId.isEmpty) return;
    final refresh = Get.find<RefreshManager>();
    await refresh.run(
      key: 'group:members:$groupId',
      ttl: const Duration(seconds: 30),
      action: () async {
        await _loadMembers();
        await membershipController.preloadMembershipsForGroups([groupId]);
        await membershipController.preloadMemberCountsForGroups([groupId]);
      },
      force: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final course = courseController.coursesCache[courseId];
      final isInactiveCourse = !(course?.isActive ?? true);
      final myUserId = activityController.currentUserId ?? '';
      final isTeacher = course?.teacherId == myUserId;
      
      final groups = groupController.groupsByCourse[courseId] ?? const [];
      _group = groups.firstWhereOrNull((g) => g.id == groupId);
      if (_group == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final category =
          (categoryController.categoriesByCourse[courseId] ?? const [])
              .firstWhereOrNull((c) => c.id == _group!.categoryId);
      final memberCount = _members.length;
      final max = category?.maxMembersPerGroup;
      final countLabel =
          max != null && max > 0 ? '$memberCount/$max' : '$memberCount';

      return CoursePageScaffold(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CourseHeader(
              title: _group!.name,
              subtitle: 'Grupo',
              showEdit: isTeacher,
              inactive: isInactiveCourse,
              onEdit: () => Get.toNamed(AppRoutes.groupEdit, arguments: {
                'courseId': courseId,
                'groupId': groupId,
              }),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Pill(text: 'Miembros: $countLabel', icon: Icons.people),
                if (category?.groupingMethod.toLowerCase() == 'manual')
                  Pill(text: 'Unión manual', icon: Icons.group_add)
                else
                  Pill(text: 'Unión aleatoria', icon: Icons.casino),
              ],
            ),
          ],
        ),
        sections: [
          SectionCard(
            title: 'Información',
            leadingIcon: Icons.info_outline,
            child: _infoSection(category),
          ),
          SectionCard(
            title: 'Miembros',
            count: _members.length,
            leadingIcon: Icons.people,
            child: InactiveGate(
              inactive: isInactiveCourse,
              child: _membersSection(isTeacher),
            ),
          ),
        ],
      );
    });
  }

  Widget _infoSection(category) {
    final pills = <Widget>[];
    if (category != null) {
      pills.add(Pill(text: 'Categoría: ${category.name}', icon: Icons.folder));
      if (category.maxMembersPerGroup != null) {
        pills.add(Pill(
            text: 'Máx: ${category.maxMembersPerGroup}',
            icon: Icons.people_alt));
      }
      pills.add(Pill(
          text:
              'Agrupación: ${(category.groupingMethod ?? '').toString().toLowerCase() == 'random' ? 'aleatoria' : 'manual'}',
          icon: Icons.group_work));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 6, runSpacing: 6, children: pills),
        
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _membersSection(bool isTeacher) {
    if (_loadingMembers) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final course = courseController.coursesCache[courseId];
    final myUserId = activityController.currentUserId ?? '';
    final isTeacherUser = course?.teacherId == myUserId;
    final category =
        (categoryController.categoriesByCourse[courseId] ?? const [])
            .firstWhereOrNull((c) => c.id == _group!.categoryId);
    final max = category?.maxMembersPerGroup;
    final joined = membershipController.myGroupIds.contains(groupId);
    final canJoin = !isTeacherUser &&
        (category?.groupingMethod.toLowerCase() == 'manual') &&
        !joined &&
        ((max == null || max == 0) || _members.length < max);
    final emptyState = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.goldAccent.withOpacity(.35), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 42, color: AppTheme.goldAccent.withOpacity(.65)),
          const SizedBox(height: 12),
          Text('Sin miembros aún',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.75),
              )),
          const SizedBox(height: 6),
          Text('Los estudiantes pueden unirse según la configuración',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.55),
              )),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canJoin)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.group_add),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.premiumBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Unirse al grupo'),
                    content: Text('¿Deseas unirte a "${_group!.name}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Unirme')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await membershipController.joinGroup(groupId);
                  await _loadMembers();
                  membershipController.preloadMembershipsForGroups([groupId]);
                  membershipController.preloadMemberCountsForGroups([groupId]);
                  setState(() {});
                }
              },
              label: const Text('UNIRME'),
            ),
          ),
        const SizedBox(height: 12),
        if (_members.isEmpty)
          emptyState
        else
          ..._members.map((m) {
            final name = _userNameCache[m.userId] ?? 'Usuario';
            return SolidListTile(
              title: name,
              subtitle:
                  'Joined: ${m.joinedAt.toIso8601String().substring(0, 10)}',
              leadingIcon: Icons.person,
              goldOutline: false,
              dense: true,
            );
          }),
      ],
    );
  }

  
}
