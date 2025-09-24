import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../domain/models/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/use_cases/group/create_group_use_case.dart';

class GroupController extends GetxController {
  final GroupRepository _groupRepository;
  final CreateGroupUseCase _createGroupUseCase;

  GroupController(this._groupRepository, this._createGroupUseCase);

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final createdGroup = Rxn<Group>();
  final groupsByCourse = <String, List<Group>>{}.obs; // courseId -> list
  final groupsByCategory = <String, List<Group>>{}.obs; // categoryId -> list

  AuthController get _auth => Get.find<AuthController>();
  String? get currentTeacherId => _auth.currentUser?.id;

  Future<List<Group>> loadByCourse(String courseId) async {
    try {
      isLoading.value = true;
      final list = await _groupRepository.getGroupsByCourse(courseId);
      groupsByCourse[courseId] = list;
      return list;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<List<Group>> loadByCategory(String categoryId) async {
    try {
      isLoading.value = true;
      final list = await _groupRepository.getGroupsByCategory(categoryId);
      groupsByCategory[categoryId] = list;
      return list;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Group?> createGroup({
    required String name,
    required String courseId,
    required String categoryId,
  }) async {
    final teacherId = currentTeacherId;
    if (teacherId == null || teacherId.isEmpty) {
      errorMessage.value = 'Usuario no autenticado';
      return null;
    }
    try {
      isLoading.value = true;
      final params = CreateGroupParams(
        name: name,
        categoryId: categoryId,
        courseId: courseId,
        teacherId: teacherId,
      );
      final g = await _createGroupUseCase(params);
      createdGroup.value = g;
      await loadByCourse(courseId);
      await loadByCategory(categoryId);
      return g;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Group?> updateGroup(Group group) async {
    try {
      isLoading.value = true;
      final updated = await _groupRepository.updateGroup(group);
      await loadByCourse(updated.courseId);
      await loadByCategory(updated.categoryId);
      return updated;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> deleteGroup(String groupId,
      {required String courseId, required String categoryId}) async {
    try {
      isLoading.value = true;
      final ok = await _groupRepository.deleteGroup(groupId);
      await loadByCourse(courseId);
      await loadByCategory(categoryId);
      return ok;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
