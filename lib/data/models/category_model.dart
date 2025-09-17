import '../../domain/models/category.dart';

/// Modelo de datos para Category con serialización JSON
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    super.iconUrl,
    required super.orderIndex,
    required super.createdAt,
    super.isActive,
  });

  /// Crear CategoryModel desde JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      orderIndex: json['order_index'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convertir CategoryModel a JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Crear copia con cambios
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    int? orderIndex,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir a entidad de dominio
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      orderIndex: orderIndex,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
