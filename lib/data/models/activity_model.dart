import '../../domain/models/activity.dart';


class ActivityModel extends Activity {
  const ActivityModel({
    required super.id,
    required super.userId,
    required super.action,
    super.entityType,
    super.entityId,
    super.details,
    required super.createdAt,
  });

  
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      details: json['details'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  
  ActivityModel copyWith({
    String? id,
    String? userId,
    String? action,
    String? entityType,
    String? entityId,
    String? details,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  
  Activity toEntity() {
    return Activity(
      id: id,
      userId: userId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      createdAt: createdAt,
    );
  }
}
