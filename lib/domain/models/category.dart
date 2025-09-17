/// Entidad de dominio para representar una categoría de curso
class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int orderIndex;
  final DateTime createdAt;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.orderIndex,
    required this.createdAt,
    this.isActive = true,
  });

  /// Categoría tiene icono
  bool get hasIcon => iconUrl != null && iconUrl!.isNotEmpty;

  /// Categoría está activa
  bool get isActiveCategory => isActive;

  /// Crear copia de la categoría con cambios
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    int? orderIndex,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, orderIndex: $orderIndex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.iconUrl == iconUrl &&
        other.orderIndex == orderIndex &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        iconUrl.hashCode ^
        orderIndex.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
