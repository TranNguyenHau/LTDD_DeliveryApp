// lib/providers/food_provider.dart

import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/category.dart' as food_category;
import '../data/mock_data.dart';

class FoodProvider with ChangeNotifier {
  final List<FoodItem> _foods = List<FoodItem>.from(mockFoods);
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  List<food_category.Category> get categories => mockCategories;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

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


void addFood(FoodItem food) {
  _foods.add(food);
  notifyListeners();
}

void deleteFood(String id) {
  _foods.removeWhere((food) => food.id == id);
  notifyListeners();
}

void updateFood(FoodItem updatedFood) {
  final index =
      _foods.indexWhere((f) => f.id == updatedFood.id);

  if (index != -1) {
    _foods[index] = updatedFood;
    notifyListeners();
  }
}



}
