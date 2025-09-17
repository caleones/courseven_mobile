/// Entidad de dominio para representar un grupo de curso
class Group {
  final String id;
  final String name;
  final String? description;
  final String courseId;
  final DateTime createdAt;
  final bool isActive;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.courseId,
    required this.createdAt,
    this.isActive = true,
  });

  /// Grupo está activo
  bool get isActiveGroup => isActive;

  /// Crear copia del grupo con cambios
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? courseId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, courseId: $courseId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Group &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.courseId == courseId &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        courseId.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
