/// Entidad de dominio para representar la membresía de un usuario a un grupo
class Membership {
  final String id;
  final String userId;
  final String groupId;
  final DateTime joinedAt;
  final bool isActive;

  const Membership({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.joinedAt,
    this.isActive = true,
  });

  /// Membresía está activa
  bool get isActiveMembership => isActive;

  /// Crear copia de la membresía con cambios
  Membership copyWith({
    String? id,
    String? userId,
    String? groupId,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return Membership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Membership(id: $id, userId: $userId, groupId: $groupId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Membership &&
        other.id == id &&
        other.userId == userId &&
        other.groupId == groupId &&
        other.joinedAt == joinedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        groupId.hashCode ^
        joinedAt.hashCode ^
        isActive.hashCode;
  }
}
