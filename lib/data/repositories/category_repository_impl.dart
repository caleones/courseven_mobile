import '../../domain/models/category.dart';
import '../models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import '../services/roble_service.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final RobleService _service;
  final Future<String?> Function()? _getAccessToken;

  CategoryRepositoryImpl(this._service,
      {Future<String?> Function()? getAccessToken})
      : _getAccessToken = getAccessToken;

  Future<String> _requireToken() async {
    if (_getAccessToken != null) {
      final t = await _getAccessToken!();
      if (t != null && t.isNotEmpty) return t;
    }
    throw Exception('Access token no disponible');
  }

  Category _fromMap(Map<String, dynamic> m) =>
      CategoryModel.fromJson(m).toEntity();

  Map<String, dynamic> _toRecord(Category c) => CategoryModel(
        id: c.id,
        name: c.name,
        description: c.description,
        courseId: c.courseId,
        teacherId: c.teacherId,
        groupingMethod: c.groupingMethod,
        maxMembersPerGroup: c.maxMembersPerGroup,
        createdAt: c.createdAt,
        isActive: c.isActive,
      ).toJson();

  @override
  Future<Category> createCategory(Category category) async {
    final token = await _requireToken();
    final record = _toRecord(category);
    if (record['_id'] == null || (record['_id'] as String).isEmpty) {
      record.remove('_id');
    }
    final res =
        await _service.insertCategory(accessToken: token, record: record);
    final inserted = (res['inserted'] as List?) ?? const [];
    if (inserted.isEmpty) {
      throw Exception('Insert de categoría no retornó registros');
    }
    return _fromMap(inserted.first as Map<String, dynamic>);
  }

  @override
  Future<List<Category>> getCategoriesByCourse(String courseId) async {
    final token = await _requireToken();
    final rows = await _service.readCategories(
      accessToken: token,
      query: {'course_id': courseId, 'is_active': 'true'},
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Category>> getCategoriesByTeacher(String teacherId) async {
    final token = await _requireToken();
    final rows = await _service.readCategories(
      accessToken: token,
      query: {'teacher_id': teacherId, 'is_active': 'true'},
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  
  @override
  Future<bool> deleteCategory(String categoryId) async {
    final token = await _requireToken();
    await _service.updateCategory(
      accessToken: token,
      id: categoryId,
      updates: {'is_active': false},
    );
    return true;
  }

  @override
  Future<List<Category>> getActiveCategories() async {
    return [];
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final token = await _requireToken();
    final rows = await _service.readCategories(accessToken: token);
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<List<Category>> getCategoriesOrdered() async {
    return [];
  }

  @override
  Future<Category?> getCategoryById(String categoryId) async {
    final token = await _requireToken();
    final rows = await _service.readCategories(
      accessToken: token,
      query: {'_id': categoryId, 'is_active': 'true'},
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  @override
  Future<bool> isCategoryNameAvailable(String name) async {
    
    final token = await _requireToken();
    final rows = await _service.readCategories(
      accessToken: token,
      query: {'name': name},
    );
    return rows.isEmpty;
  }

  @override
  Future<List<Category>> searchCategoriesByName(String name) async {
    
    final token = await _requireToken();
    final rows = await _service.readCategories(
      accessToken: token,
      query: {'name': name},
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final token = await _requireToken();
    final updates = <String, dynamic>{
      'name': category.name,
      'description': category.description,
      'course_id': category.courseId,
      'teacher_id': category.teacherId,
      'grouping_method': category.groupingMethod,
      'max_members_per_group': category.maxMembersPerGroup,
      'is_active': category.isActive,
    };
    final res = await _service.updateCategory(
      accessToken: token,
      id: category.id,
      updates: updates,
    );
    final updated = (res['updated'] as List?)?.cast<Map<String, dynamic>>() ??
        (res['data'] is List
            ? (res['data'] as List).cast<Map<String, dynamic>>()
            : const <Map<String, dynamic>>[]);
    if (updated.isNotEmpty) {
      return _fromMap(updated.first);
    }
    
    final again = await getCategoryById(category.id);
    if (again == null) throw Exception('No se pudo leer categoría actualizada');
    return again;
  }

  @override
  Future<bool> updateCategoriesOrder(List<String> categoryIds) async {
    throw UnimplementedError();
  }
}
