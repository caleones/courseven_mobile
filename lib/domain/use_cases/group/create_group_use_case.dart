import '../../models/group.dart';
import '../../repositories/group_repository.dart';

class CreateGroupParams {
  final String name;
  final String categoryId;
  final String courseId;
  final String teacherId;

  const CreateGroupParams({
    required this.name,
    required this.categoryId,
    required this.courseId,
    required this.teacherId,
  });
}

class CreateGroupUseCase {
  final GroupRepository _repository;
  CreateGroupUseCase(this._repository);

  Future<Group> call(CreateGroupParams p) async {
    final group = Group(
      id: '',
      name: p.name.trim(),
      categoryId: p.categoryId,
      courseId: p.courseId,
      teacherId: p.teacherId,
      createdAt: DateTime.now(),
      isActive: true,
    );
    return _repository.createGroup(group);
  }
}
