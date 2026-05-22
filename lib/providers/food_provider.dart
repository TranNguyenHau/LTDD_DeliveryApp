// lib/providers/food_provider.dart
// Đọc/ghi món ăn và danh mục từ Firestore

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/category.dart' as food_category;
import '../models/food_item.dart';

class FoodProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<FoodItem> _foods = [];
  List<food_category.Category> _categories = [];
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  StreamSubscription? _foodsSub;
  StreamSubscription? _categoriesSub;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Danh mục hiển thị UI (có thêm "Tất cả")
  List<food_category.Category> get categories => [
        food_category.Category.all,
        ..._categories,
      ];

  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  List<FoodItem> get foods => List.unmodifiable(_foods);

  List<FoodItem> get filteredFoods {
    return _foods.where((food) {
      final matchCategory = _selectedCategoryId == 'all' ||
          food.categoryId == _selectedCategoryId;
      final matchSearch = _searchQuery.isEmpty ||
          food.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  List<FoodItem> get popularFoods =>
      _foods.where((f) => f.isPopular).toList();

  FoodProvider() {
    _listenFirestore();
  }

  void _listenFirestore() {
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

    _foodsSub = _db.collection(FirestoreCollections.foods).snapshots().listen(
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

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  FoodItem? getFoodById(String id) {
    try {
      return _foods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Thêm món mới lên Firestore
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

  /// Cập nhật món trên Firestore
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

  /// Xóa món khỏi Firestore
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

  @override
  void dispose() {
    _foodsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
