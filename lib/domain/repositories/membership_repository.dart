import '../models/membership.dart';


abstract class MembershipRepository {
  
  Future<Membership?> getMembershipById(String membershipId);

  
  Future<List<Membership>> getMembershipsByUserId(String userId);

  
  Future<List<Membership>> getMembershipsByGroupId(String groupId);

  
  Future<Membership> createMembership(Membership membership);

  
  Future<Membership> updateMembership(Membership membership);

  
  Future<bool> deleteMembership(String membershipId);

  
  Future<bool> isUserMemberOfGroup(String userId, String groupId);

  
  Future<List<Membership>> getActiveMemberships();

  
  Future<List<Membership>> getMembershipsPaginated({
    int page = 1,
    int limit = 10,
  });
}
