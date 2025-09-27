import 'package:get/get.dart';
import '../../domain/models/membership.dart';
import '../../domain/use_cases/membership/join_group_use_case.dart';
import 'auth_controller.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../../core/utils/app_event_bus.dart';

class MembershipController extends GetxController {
  final JoinGroupUseCase _joinGroupUseCase;
  final MembershipRepository _membershipRepository;

  MembershipController(this._joinGroupUseCase, this._membershipRepository);

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final RxSet<String> myGroupIds =
      <String>{}.obs; 
  final RxMap<String, int> groupMemberCounts =
      <String, int>{}.obs; 

  AuthController get _auth => Get.find<AuthController>();
  String? get currentUserId => _auth.currentUser?.id;

  Future<void> preloadMembershipsForGroups(List<String> groupIds) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty || groupIds.isEmpty) return;
    try {
      isLoading.value = true;
      
      
      final myMemberships =
          await _membershipRepository.getMembershipsByUserId(userId);
      final joinedIds = myMemberships.map((m) => m.groupId).toSet();
      myGroupIds
        ..clear()
        ..addAll(groupIds.where((gid) => joinedIds.contains(gid)));
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> preloadMemberCountsForGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return;
    try {
      isLoading.value = true;
      
      for (final gid in groupIds) {
        final count = await _membershipRepository.getMembershipsByGroupId(gid);
        groupMemberCounts[gid] = count.length;
      }
      groupMemberCounts.refresh();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<int> getMemberCount(String groupId) async {
    final cached = groupMemberCounts[groupId];
    if (cached != null) return cached;
    try {
      final list = await _membershipRepository.getMembershipsByGroupId(groupId);
      groupMemberCounts[groupId] = list.length;
      groupMemberCounts.refresh();
      update();
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  Future<Membership?> joinGroup(String groupId) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      errorMessage.value = 'Usuario no autenticado';
      return null;
    }
    try {
      isLoading.value = true;
      final m = await _joinGroupUseCase(
          JoinGroupParams(userId: userId, groupId: groupId));
      myGroupIds.add(groupId);

      
      try {
        final groupRepo = Get.find<GroupRepository>();
        final g = await groupRepo.getGroupById(groupId);
        if (Get.isRegistered<AppEventBus>() && g != null) {
          Get.find<AppEventBus>()
              .publish(MembershipJoinedEvent(groupId, g.courseId));
        }
        
        await getMemberCount(groupId);
      } catch (_) {}
      return m;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
