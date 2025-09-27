
class Activity {
  final String id;
  final String userId;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? details;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  
  bool get hasEntity => entityType != null && entityId != null;

  
  Activity copyWith({
    String? id,
    String? userId,
    String? action,
    String? entityType,
    String? entityId,
    String? details,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Activity(id: $id, userId: $userId, action: $action)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Activity &&
        other.id == id &&
        other.userId == userId &&
        other.action == action &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.details == details &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        action.hashCode ^
        entityType.hashCode ^
        entityId.hashCode ^
        details.hashCode ^
        createdAt.hashCode;
  }
}
