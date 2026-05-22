// lib/providers/order_provider.dart
// Đọc/ghi đơn hàng từ Firestore — cập nhật realtime

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

/// Bộ lọc trạng thái trên màn Đơn hàng
enum OrderFilter {
  all,
  pending,
  confirmed,
  delivering,
  done,
}

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Order> _orders = [];
  String? _userId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;

  bool _isLoading = false;
  bool _isPlacing = false;
  String? _errorMessage;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isPlacing => _isPlacing;
  String? get errorMessage => _errorMessage;

  /// Đơn đang xử lý (chưa hoàn thành)
  List<Order> get activeOrders => _orders
      .where((o) => o.status != OrderStatus.delivered)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Đơn đã hoàn thành — sort mới nhất trước
  List<Order> get completedOrders => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Tổng tiền đã chi tiêu (đơn đã giao)
  double get totalSpent =>
      completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

  /// Lọc đơn hiện tại theo tab trạng thái
  List<Order> filteredActiveOrders(OrderFilter filter) {
    final active = activeOrders;
    switch (filter) {
      case OrderFilter.all:
        return active;
      case OrderFilter.pending:
        return active.where((o) => o.status == OrderStatus.pending).toList();
      case OrderFilter.confirmed:
        return active
            .where((o) =>
                o.status == OrderStatus.confirmed ||
                o.status == OrderStatus.preparing)
            .toList();
      case OrderFilter.delivering:
        return active
            .where((o) => o.status == OrderStatus.delivering)
            .toList();
      case OrderFilter.done:
        return active.where((o) => o.status == OrderStatus.delivered).toList();
    }
  }

  /// Gắn user và lắng nghe đơn hàng realtime
  Future<void> bindUser(String userId) async {
    if (_userId == userId && _ordersSub != null) return;

    await _ordersSub?.cancel();
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _ordersSub = _db
        .collection(FirestoreCollections.orders)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snap) {
        _orders = snap.docs
            .map((d) => Order.fromMap(d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Không tải được đơn hàng: $e';
        notifyListeners();
      },
    );
  }

  /// Đặt hàng và lưu lên Firestore
  Future<Order?> placeOrder({
    required String userId,
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
  }) async {
    _isPlacing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      final order = Order(
        id: orderId,
        userId: userId,
        items: items
            .map((i) => CartItem(food: i.food, quantity: i.quantity))
            .toList(),
        totalAmount: totalAmount,
        deliveryAddress: deliveryAddress,
      );

      await _db
          .collection(FirestoreCollections.orders)
          .doc(orderId)
          .set(order.toMap());

      return order;
    } catch (e) {
      _errorMessage = 'Không thể đặt hàng: $e';
      notifyListeners();
      return null;
    } finally {
      _isPlacing = false;
      notifyListeners();
    }
  }

  /// Hủy lắng nghe khi đăng xuất
  Future<void> clear() async {
    await _ordersSub?.cancel();
    _ordersSub = null;
    _userId = null;
    _orders = [];
    _isLoading = false;
    _isPlacing = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}
