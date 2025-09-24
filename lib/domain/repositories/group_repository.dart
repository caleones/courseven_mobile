import '../models/group.dart';

/// Repositorio abstracto para manejo de grupos
abstract class GroupRepository {
  /// Obtener grupo por ID
  Future<Group?> getGroupById(String groupId);

  /// Obtener grupos por curso
  Future<List<Group>> getGroupsByCourse(String courseId);

  /// Crear nuevo grupo
  Future<Group> createGroup(Group group);

  /// Obtener grupos por categoría
  Future<List<Group>> getGroupsByCategory(String categoryId);

  /// Obtener grupos por profesor
  Future<List<Group>> getGroupsByTeacher(String teacherId);

  /// Actualizar grupo existente
  Future<Group> updateGroup(Group group);

  /// Eliminar grupo (soft delete)
  Future<bool> deleteGroup(String groupId);

  /// Buscar grupos por nombre
  Future<List<Group>> searchGroupsByName(String name);

  /// Obtener grupos activos
  Future<List<Group>> getActiveGroups();

  /// Obtener grupos paginados
  Future<List<Group>> getGroupsPaginated({
    int page = 1,
    int limit = 10,
    String? courseId,
  });

  /// Verificar si nombre está disponible en el curso
  Future<bool> isGroupNameAvailableInCourse(String name, String courseId);
}
