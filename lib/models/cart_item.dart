// lib/models/cart_item.dart

import 'food_item.dart';

class CartItem {
  final FoodItem food;
  int quantity;

  CartItem({
    required this.food,
    this.quantity = 1,
  });

  double get totalPrice => food.price * quantity;
}
