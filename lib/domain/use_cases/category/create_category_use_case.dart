import '../../models/category.dart';
import '../../repositories/category_repository.dart';

class CreateCategoryParams {
  final String name;
  final String? description;
  final String courseId;
  final String teacherId;
  final String groupingMethod; // 'manual' | 'random'
  final int? maxMembersPerGroup;

  const CreateCategoryParams({
    required this.name,
    this.description,
    required this.courseId,
    required this.teacherId,
    required this.groupingMethod,
    this.maxMembersPerGroup,
  });
}

class CreateCategoryUseCase {
  final CategoryRepository _repository;
  CreateCategoryUseCase(this._repository);

  Future<Category> call(CreateCategoryParams p) async {
    final category = Category(
      id: '',
      name: p.name.trim(),
      description: p.description?.trim(),
      courseId: p.courseId,
      teacherId: p.teacherId,
      groupingMethod: p.groupingMethod,
      maxMembersPerGroup: p.maxMembersPerGroup,
      createdAt: DateTime.now(),
      isActive: true,
    );
    return _repository.createCategory(category);
  }
}
