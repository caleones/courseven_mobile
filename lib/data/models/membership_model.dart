import '../../domain/models/membership.dart';

/// Modelo de datos para Membership con serialización JSON
class MembershipModel extends Membership {
  const MembershipModel({
    required super.id,
    required super.userId,
    required super.groupId,
    required super.joinedAt,
    super.isActive,
  });

  /// Crear MembershipModel desde JSON
  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: json['_id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String,
      // Nota: en la DB actual la columna está mal escrita como "joinet_at".
      // Soportamos ambas llaves para compatibilidad hacia atrás/adelante.
      joinedAt: (json['joined_at'] ?? json['joinet_at']) != null
          ? DateTime.parse((json['joined_at'] ?? json['joinet_at']) as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convertir MembershipModel a JSON
  Map<String, dynamic> toJson() {
    // Para inserciones, usamos únicamente la clave con el typo actual de la DB (joinet_at)
    final when = joinedAt.toIso8601String();
    return {
      '_id': id,
      'user_id': userId,
      'group_id': groupId,
      'joinet_at': when, // compat con esquema actual
      'is_active': isActive,
    };
  }

  /// Crear copia con cambios
  MembershipModel copyWith({
    String? id,
    String? userId,
    String? groupId,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir a entidad de dominio
  Membership toEntity() {
    return Membership(
      id: id,
      userId: userId,
      groupId: groupId,
      joinedAt: joinedAt,
      isActive: isActive,
    );
  }
}
