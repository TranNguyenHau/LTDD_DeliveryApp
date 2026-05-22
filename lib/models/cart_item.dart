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

  /// Chuyển sang Map (lưu kèm đơn hàng trên Firestore)
  Map<String, dynamic> toMap() {
    return {
      'foodId': food.id,
      'foodName': food.name,
      'foodImageUrl': food.imageUrl,
      'price': food.price,
      'quantity': quantity,
    };
  }

  /// Khôi phục CartItem từ Map đơn hàng (cần FoodItem đầy đủ hoặc dữ liệu tối thiểu)
  factory CartItem.fromMap(Map<String, dynamic> map, {FoodItem? food}) {
    final foodItem = food ??
        FoodItem(
          id: map['foodId'] as String? ?? '',
          name: map['foodName'] as String? ?? '',
          description: '',
          price: (map['price'] as num?)?.toDouble() ?? 0,
          imageUrl: map['foodImageUrl'] as String? ?? '',
          categoryId: '',
        );
    return CartItem(
      food: foodItem,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
