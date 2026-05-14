// lib/providers/cart_provider.dart

import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool containsFood(String foodId) => _items.containsKey(foodId);

  int quantityOf(String foodId) => _items[foodId]?.quantity ?? 0;

  void addItem(FoodItem food) {
    if (_items.containsKey(food.id)) {
      _items[food.id]!.quantity++;
    } else {
      _items[food.id] = CartItem(food: food);
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    if (!_items.containsKey(foodId)) return;
    if (_items[foodId]!.quantity > 1) {
      _items[foodId]!.quantity--;
    } else {
      _items.remove(foodId);
    }
    notifyListeners();
  }

  void deleteItem(String foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
