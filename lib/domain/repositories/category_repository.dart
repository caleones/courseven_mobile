import '../models/category.dart';


abstract class CategoryRepository {
  
  Future<Category?> getCategoryById(String categoryId);

  
  Future<List<Category>> getAllCategories();

  
  Future<Category> createCategory(Category category);

  
  Future<List<Category>> getCategoriesByCourse(String courseId);

  
  Future<List<Category>> getCategoriesByTeacher(String teacherId);

  
  Future<Category> updateCategory(Category category);

  
  Future<bool> deleteCategory(String categoryId);

  
  Future<List<Category>> searchCategoriesByName(String name);

  
  Future<List<Category>> getActiveCategories();

  
  Future<List<Category>> getCategoriesOrdered();

  
  Future<bool> updateCategoriesOrder(List<String> categoryIds);

  
  Future<bool> isCategoryNameAvailable(String name);
}
