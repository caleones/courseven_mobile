import '../../models/membership.dart';
import '../../repositories/membership_repository.dart';
import '../../repositories/group_repository.dart';
import '../../repositories/category_repository.dart';

class JoinGroupParams {
  final String userId;
  final String groupId;
  JoinGroupParams({required this.userId, required this.groupId});
}

class JoinGroupUseCase {
  final MembershipRepository membershipRepository;
  final GroupRepository groupRepository;
  final CategoryRepository categoryRepository;

  JoinGroupUseCase(
      this.membershipRepository, this.groupRepository, this.categoryRepository);

  Future<Membership> call(JoinGroupParams params) async {
    
    final already = await membershipRepository.isUserMemberOfGroup(
        params.userId, params.groupId);
    if (already) {
      throw Exception('Ya eres miembro de este grupo');
    }

    
    final group = await groupRepository.getGroupById(params.groupId);
    if (group == null) throw Exception('Grupo no encontrado');

    
    
    
    
    final category = await categoryRepository.getCategoryById(group.categoryId);
    if (category == null) throw Exception('Categoría no encontrada');

    if (category.groupingMethod.toLowerCase() != 'manual') {
      throw Exception('No puedes unirte manualmente. Asignación aleatoria');
    }

    
    final myMemberships =
        await membershipRepository.getMembershipsByUserId(params.userId);
    for (final m in myMemberships) {
      final g = await groupRepository.getGroupById(m.groupId);
      if (g != null && g.categoryId == category.id) {
        throw Exception(
            'Ya perteneces a un grupo de la categoría "${category.name}"');
      }
    }

    
    if (category.maxMembersPerGroup != null &&
        category.maxMembersPerGroup! > 0) {
      final members =
          await membershipRepository.getMembershipsByGroupId(group.id);
      if (members.length >= category.maxMembersPerGroup!) {
        throw Exception('Este grupo alcanzó su capacidad máxima');
      }
    }

    
    final membership = Membership(
      id: '',
      userId: params.userId,
      groupId: params.groupId,
      joinedAt: DateTime.now(),
      isActive: true,
    );
    return await membershipRepository.createMembership(membership);
  }
}
