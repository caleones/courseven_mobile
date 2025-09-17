import '../models/membership.dart';

/// Repositorio abstracto para manejo de membresías
abstract class MembershipRepository {
  /// Obtener membresía por ID
  Future<Membership?> getMembershipById(String membershipId);

  /// Obtener membresías por usuario
  Future<List<Membership>> getMembershipsByUserId(String userId);

  /// Obtener membresías por grupo
  Future<List<Membership>> getMembershipsByGroupId(String groupId);

  /// Crear nueva membresía
  Future<Membership> createMembership(Membership membership);

  /// Actualizar membresía existente
  Future<Membership> updateMembership(Membership membership);

  /// Eliminar membresía (soft delete)
  Future<bool> deleteMembership(String membershipId);

  /// Verificar si usuario es miembro del grupo
  Future<bool> isUserMemberOfGroup(String userId, String groupId);

  /// Obtener membresías activas
  Future<List<Membership>> getActiveMemberships();

  /// Obtener membresías paginadas
  Future<List<Membership>> getMembershipsPaginated({
    int page = 1,
    int limit = 10,
  });
}
