import '../models/category.dart';

/// Repositorio abstracto para manejo de categorías
abstract class CategoryRepository {
  /// Obtener categoría por ID
  Future<Category?> getCategoryById(String categoryId);

  /// Obtener todas las categorías
  Future<List<Category>> getAllCategories();

  /// Crear nueva categoría
  Future<Category> createCategory(Category category);

  /// Obtener categorías de un curso
  Future<List<Category>> getCategoriesByCourse(String courseId);

  /// Obtener categorías del profesor
  Future<List<Category>> getCategoriesByTeacher(String teacherId);

  /// Actualizar categoría existente
  Future<Category> updateCategory(Category category);

  /// Eliminar categoría (soft delete)
  Future<bool> deleteCategory(String categoryId);

  /// Buscar categorías por nombre
  Future<List<Category>> searchCategoriesByName(String name);

  /// Obtener categorías activas
  Future<List<Category>> getActiveCategories();

  /// Obtener categorías ordenadas
  Future<List<Category>> getCategoriesOrdered();

  /// Actualizar orden de categorías
  Future<bool> updateCategoriesOrder(List<String> categoryIds);

  /// Verificar si nombre está disponible
  Future<bool> isCategoryNameAvailable(String name);
}
