import '../models/group.dart';


abstract class GroupRepository {
  
  Future<Group?> getGroupById(String groupId);

  
  Future<List<Group>> getGroupsByCourse(String courseId);

  
  Future<Group> createGroup(Group group);

  
  Future<List<Group>> getGroupsByCategory(String categoryId);

  
  Future<List<Group>> getGroupsByTeacher(String teacherId);

  
  Future<Group> updateGroup(Group group);

  
  Future<bool> deleteGroup(String groupId);

  
  Future<List<Group>> searchGroupsByName(String name);

  
  Future<List<Group>> getActiveGroups();

  
  Future<List<Group>> getGroupsPaginated({
    int page = 1,
    int limit = 10,
    String? courseId,
  });

  
  Future<bool> isGroupNameAvailableInCourse(String name, String courseId);
}
