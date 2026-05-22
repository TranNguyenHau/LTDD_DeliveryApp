// lib/models/order.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus { pending, confirmed, preparing, delivering, completed, cancelled }

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final String? couponCode;
  final double discountAmount;
  final DateTime createdAt;
  final String deliveryAddress;
  final DateTime? cancelledAt;
  final String? cancelReason;
  OrderStatus status;

  // New fields for address picker
  final double? lat;
  final double? lng;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.couponCode,
    this.discountAmount = 0.0,
    required this.deliveryAddress,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
    this.cancelledAt,
    this.cancelReason,
    this.lat,
    this.lng,
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
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  /// Giá trị status lưu trên Firestore
  String get statusValue => status.name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'deliveryAddress': deliveryAddress,
      'status': statusValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelReason': cancelReason,
      'lat': lat,
      'lng': lng,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      couponCode: map['couponCode'] as String?,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      status: _parseStatus(map['status'] as String?),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      cancelledAt: _parseDateTime(map['cancelledAt']),
      cancelReason: map['cancelReason'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  static OrderStatus _parseStatus(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
