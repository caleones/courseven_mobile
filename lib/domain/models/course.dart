


class Course {
  final String id;
  final String name;
  final String description;
  final String joinCode;
  final String teacherId;
  final DateTime createdAt;
  final bool isActive;

  const Course({
    required this.id,
    required this.name,
    required this.description,
    required this.joinCode,
    required this.teacherId,
    required this.createdAt,
    this.isActive = true,
  });

  
  bool get isActiveCourse => isActive;

  
  Course copyWith({
    String? id,
    String? name,
    String? description,
    String? joinCode,
    String? teacherId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      joinCode: joinCode ?? this.joinCode,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Course(id: $id, name: $name, teacherId: $teacherId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Course &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.joinCode == joinCode &&
        other.teacherId == teacherId &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        joinCode.hashCode ^
        teacherId.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
