import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/food.dart';
import '../models/store.dart';
import '../repositories/food_repository.dart';

/// ViewModel cho danh sách món ăn ở Home Screen: nạp dữ liệu, tìm kiếm và
/// lọc theo danh mục. Logic lọc nằm ở đây (không nằm trong widget) để có
/// thể unit test độc lập với UI nếu cần mở rộng sau này.
class FoodViewModel extends ChangeNotifier {
  final FoodRepository _repository;

  FoodViewModel({FoodRepository? repository}) : _repository = repository ?? FoodRepository();

  List<Food> _allFoods = [];
  List<FoodCategory> categories = [];
  List<Store> stores = [];
  bool isLoading = false;

  String searchQuery = '';

  /// null = chưa chọn danh mục nào (hiển thị filter "All").
  String? selectedCategoryId;

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    final results = await Future.wait([
      _repository.getAllFoods(),
      _repository.getAllCategories(),
      _repository.getAllStores(),
    ]);
    _allFoods = results[0] as List<Food>;
    categories = results[1] as List<FoodCategory>;
    stores = results[2] as List<Store>;
    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  List<Food> get filteredFoods {
    return _allFoods.where((f) {
      final matchesCategory = selectedCategoryId == null || f.categoryId == selectedCategoryId;
      final matchesQuery = searchQuery.isEmpty || f.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesQuery && f.isAvailable;
    }).toList();
  }

  /// Danh sách gợi ý ("We Recommend") - lấy các món đang bán, đánh giá cao
  /// nhất. Lọc [Food.isAvailable] giống [filteredFoods] để món đã bị chủ
  /// quán tắt bán không lọt vào đây.
  List<Food> get recommended {
    final sorted = _allFoods.where((f) => f.isAvailable).toList()..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  Food? getById(String foodId) {
    for (final f in _allFoods) {
      if (f.id == foodId) return f;
    }
    return null;
  }

  FoodCategory? getCategoryById(String categoryId) {
    for (final c in categories) {
      if (c.id == categoryId) return c;
    }
    return null;
  }

  Store? getStoreById(String storeId) {
    for (final s in stores) {
      if (s.id == storeId) return s;
    }
    return null;
  }

  /// Toàn bộ món (kể cả đang ẩn) của 1 cửa hàng - dùng cho màn Quản lý quán
  /// của chủ quán, khác với [filteredFoods] chỉ hiển thị món đang bán.
  List<Food> foodsForStore(String storeId) {
    return _allFoods.where((f) => f.storeId == storeId).toList();
  }

  Future<void> addFood(Food food) async {
    await _repository.insertFood(food);
    await loadAll();
  }

  Future<void> updateFood(Food food) async {
    await _repository.updateFood(food);
    await loadAll();
  }

  Future<void> deleteFood(String id) async {
    await _repository.deleteFood(id);
    await loadAll();
  }

  Future<void> toggleAvailability(Food food) async {
    await updateFood(food.copyWith(isAvailable: !food.isAvailable));
  }
}
