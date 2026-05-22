// lib/providers/food_provider.dart
// Đọc/ghi món ăn và danh mục từ Firestore
// ✅ Server-side filtering: category + search được xử lý trên Firestore

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/category.dart' as food_category;
import '../models/food_item.dart';

class FoodProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<FoodItem> _foods = [];
  List<FoodItem> _popularFoods = [];
  List<food_category.Category> _categories = [];

  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Tách riêng subscription cho từng query
  StreamSubscription? _foodsSub;
  StreamSubscription? _popularSub;
  StreamSubscription? _categoriesSub;

  // Debounce search để không query liên tục khi user đang gõ
  Timer? _searchDebounce;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<food_category.Category> get categories => [
    food_category.Category.all,
    ..._categories,
  ];

  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  // ✅ Trả về kết quả đã được filter từ Firestore (không filter ở client nữa)
  List<FoodItem> get filteredFoods => List.unmodifiable(_foods);
  List<FoodItem> get popularFoods => List.unmodifiable(_popularFoods);

  // ✅ Giữ getter 'foods' để tương thích với admin_food_screen.dart
  List<FoodItem> get foods => List.unmodifiable(_foods);

  FoodProvider() {
    _listenCategories();
    _listenPopularFoods();
    _listenFoodsWithFilter();
  }

  // ─── Lắng nghe danh mục ───────────────────────────────────────────────────

  void _listenCategories() {
    _categoriesSub = _db
        .collection(FirestoreCollections.categories)
        .orderBy('name')
        .snapshots()
        .listen(
          (snap) {
        _categories = snap.docs
            .map((d) => food_category.Category.fromMap(d.data()))
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không tải được danh mục: $e';
        notifyListeners();
      },
    );
  }

  // ─── Lắng nghe món phổ biến (query riêng, không bị ảnh hưởng bởi filter) ──

  void _listenPopularFoods() {
    _popularSub = _db
        .collection(FirestoreCollections.foods)
        .where('isPopular', isEqualTo: true)
        .limit(10) // ✅ Giới hạn số lượng, tiết kiệm Firestore reads
        .snapshots()
        .listen(
          (snap) {
        _popularFoods =
            snap.docs.map((d) => FoodItem.fromMap(d.data())).toList();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không tải được món phổ biến: $e';
        notifyListeners();
      },
    );
  }

  // ─── Query chính: filter theo category + search trên Firestore ────────────

  void _listenFoodsWithFilter() {
    _foodsSub?.cancel(); // Hủy subscription cũ trước khi tạo mới
    _isLoading = true;
    notifyListeners();

    Query<Map<String, dynamic>> query =
    _db.collection(FirestoreCollections.foods);

    // ✅ Filter category trên Firestore (không tải toàn bộ về client)
    if (_selectedCategoryId != 'all') {
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
    }

    // ✅ Search theo tên: Firestore hỗ trợ prefix search
    // Ví dụ: search "phở" sẽ tìm tất cả tên bắt đầu bằng "phở"
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      query = query
          .orderBy('name')
          .startAt([searchLower]).endAt(['$searchLower\uf8ff']);
    } else {
      query = query.orderBy('name');
    }

    // ✅ Giới hạn 50 món mỗi lần load (pagination-ready)
    query = query.limit(50);

    _foodsSub = query.snapshots().listen(
          (snap) {
        _foods = snap.docs.map((d) => FoodItem.fromMap(d.data())).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Không tải được món ăn: $e';
        notifyListeners();
      },
    );
  }

  // ─── Chọn danh mục → query lại Firestore ─────────────────────────────────

  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) return; // Không query nếu không đổi
    _selectedCategoryId = categoryId;
    _listenFoodsWithFilter();
  }

  // ─── Search với debounce 400ms → tránh query liên tục khi đang gõ ────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _listenFoodsWithFilter();
    });
  }

  // ─── Lấy món theo ID (ưu tiên lấy từ cache, fallback lên Firestore) ───────

  FoodItem? getFoodById(String id) {
    try {
      return _foods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Lấy từ Firestore nếu không có trong cache (dùng cho food_detail_screen)
  Future<FoodItem?> fetchFoodById(String id) async {
    final cached = getFoodById(id);
    if (cached != null) return cached;
    try {
      final doc = await _db
          .collection(FirestoreCollections.foods)
          .doc(id)
          .get();
      if (doc.exists) return FoodItem.fromMap(doc.data()!);
    } catch (_) {}
    return null;
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<String?> addFood(FoodItem food) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _db
          .collection(FirestoreCollections.foods)
          .doc(food.id)
          .set(food.toMap());
      return null;
    } catch (e) {
      return 'Không thể thêm món: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> updateFood(FoodItem updatedFood) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _db
          .collection(FirestoreCollections.foods)
          .doc(updatedFood.id)
          .update(updatedFood.toMap());
      return null;
    } catch (e) {
      return 'Không thể cập nhật món: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteFood(String id) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _db.collection(FirestoreCollections.foods).doc(id).delete();
      return null;
    } catch (e) {
      return 'Không thể xóa món: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clear() {
    _selectedCategoryId = 'all';
    _searchQuery = '';
    _errorMessage = null;
    _listenFoodsWithFilter();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _foodsSub?.cancel();
    _popularSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}