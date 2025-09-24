import 'package:get/get.dart';
import '../../domain/models/membership.dart';
import '../../domain/use_cases/membership/join_group_use_case.dart';
import 'auth_controller.dart';
import '../../domain/repositories/membership_repository.dart';

class MembershipController extends GetxController {
  final JoinGroupUseCase _joinGroupUseCase;
  final MembershipRepository _membershipRepository;

  MembershipController(this._joinGroupUseCase, this._membershipRepository);

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final RxSet<String> myGroupIds =
      <String>{}.obs; // cache of groupIds user joined
  final RxMap<String, int> groupMemberCounts =
      <String, int>{}.obs; // groupId -> count

  AuthController get _auth => Get.find<AuthController>();
  String? get currentUserId => _auth.currentUser?.id;

  Future<void> preloadMembershipsForGroups(List<String> groupIds) async {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty || groupIds.isEmpty) return;
    try {
      isLoading.value = true;
      // Estrategia eficiente y robusta: cargo todas mis membresías una vez
      // y marco cuáles coinciden con los groupIds dados.
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
      // fetch counts sequentially to avoid overwhelming backend
      for (final gid in groupIds) {
        final count = await _membershipRepository.getMembershipsByGroupId(gid);
        groupMemberCounts[gid] = count.length;
      }
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
