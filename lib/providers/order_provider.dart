// lib/providers/order_provider.dart

import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  Order placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
  }) {
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: items.map((i) => CartItem(food: i.food, quantity: i.quantity)).toList(),
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
    );

    _orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
