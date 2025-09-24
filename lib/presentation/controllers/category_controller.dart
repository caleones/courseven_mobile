import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/use_cases/category/create_category_use_case.dart';

class CategoryController extends GetxController {
  final CategoryRepository _categoryRepository;
  final CreateCategoryUseCase _createCategoryUseCase;

  CategoryController(this._categoryRepository, this._createCategoryUseCase);

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final createdCategory = Rxn<Category>();
  final categoriesByCourse = <String, List<Category>>{}.obs; // courseId -> list

  AuthController get _auth => Get.find<AuthController>();
  String? get currentTeacherId => _auth.currentUser?.id;

  Future<List<Category>> loadByCourse(String courseId) async {
    try {
      isLoading.value = true;
      final list = await _categoryRepository.getCategoriesByCourse(courseId);
      categoriesByCourse[courseId] = list;
      return list;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Category?> createCategory({
    required String name,
    String? description,
    required String courseId,
    required String groupingMethod,
    int? maxMembersPerGroup,
  }) async {
    final teacherId = currentTeacherId;
    if (teacherId == null || teacherId.isEmpty) {
      errorMessage.value = 'Usuario no autenticado';
      return null;
    }
    try {
      isLoading.value = true;
      final params = CreateCategoryParams(
        name: name,
        description: description,
        courseId: courseId,
        teacherId: teacherId,
        groupingMethod: groupingMethod,
        maxMembersPerGroup: maxMembersPerGroup,
      );
      final cat = await _createCategoryUseCase(params);
      createdCategory.value = cat;
      // refresh cache
      await loadByCourse(courseId);
      return cat;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<Category?> updateCategory(Category category) async {
    try {
      isLoading.value = true;
      final updated = await _categoryRepository.updateCategory(category);
      await loadByCourse(updated.courseId);
      return updated;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> deleteCategory(String categoryId, String courseId) async {
    try {
      isLoading.value = true;
      final ok = await _categoryRepository.deleteCategory(categoryId);
      await loadByCourse(courseId);
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
