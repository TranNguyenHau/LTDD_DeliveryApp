// lib/models/order.dart

import 'cart_item.dart';

enum OrderStatus { pending, confirmed, preparing, delivering, delivered }

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final String deliveryAddress;
  OrderStatus status;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
    }
  }
}
