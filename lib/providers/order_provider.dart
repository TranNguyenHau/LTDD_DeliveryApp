// lib/providers/order_provider.dart
// Đọc/ghi đơn hàng từ Firestore — cập nhật realtime

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import 'notification_provider.dart';

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
  Order? _lastPlacedOrder;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isPlacing => _isPlacing;
  String? get errorMessage => _errorMessage;
  Order? get lastPlacedOrder => _lastPlacedOrder;

  /// Đơn đang xử lý (chưa hoàn thành)
  List<Order> get activeOrders => _orders
      .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Đơn đã hoàn thành hoặc đã hủy — sort mới nhất trước
  List<Order> get completedOrders => _orders
      .where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Tổng tiền đã chi tiêu (đơn đã giao thành công)
  double get totalSpent =>
      _orders.where((o) => o.status == OrderStatus.completed)
      .fold(0.0, (previousValue, o) => previousValue + o.totalAmount);

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
        return _orders.where((o) => o.status == OrderStatus.completed).toList();
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
    String? couponCode,
    double? discountAmount,
  }) async {
    _isPlacing = true;
    _errorMessage = null;
    _lastPlacedOrder = null;
    notifyListeners();

    // Fetch current user and log it
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;
    debugPrint('PLACE_ORDER: Attempting order for userId=$userId (Current Auth UID=$currentUserId)');

    try {
      final orderRef = _db.collection(FirestoreCollections.orders).doc();
      final orderId = orderRef.id;

      final order = Order(
        id: orderId,
        userId: userId,
        items: items
            .map((i) => CartItem(food: i.food, quantity: i.quantity))
            .toList(),
        totalAmount: totalAmount,
        deliveryAddress: deliveryAddress,
        couponCode: couponCode,
        discountAmount: discountAmount ?? 0.0,
      );

      await _db.runTransaction((transaction) async {
        // ─── ALL READS FIRST ───────────────────────
        DocumentSnapshot? couponSnap;
        if (couponCode != null && couponCode.trim().isNotEmpty) {
          final couponRef = _db.collection(FirestoreCollections.coupons).doc(couponCode);
          debugPrint('PLACE_ORDER: Reading coupon document: ${couponRef.path}');
          couponSnap = await transaction.get(couponRef);
          
          if (couponSnap.exists) {
            final couponData = couponSnap.data() as Map<String, dynamic>?;
            
            // Check if coupon is still active (Race condition check)
            final isActive = couponData?['isActive'] ?? false;
            if (!isActive) {
              throw Exception('Mã giảm giá không còn hiệu lực');
            }

            final perUserLimit = (couponData?['perUserLimit'] as num?)?.toInt() ?? 0;
            if (perUserLimit > 0 && currentUserId != null) {
              final userUsageRef = _db
                  .collection(FirestoreCollections.coupons)
                  .doc(couponCode)
                  .collection('usedBy')
                  .doc(currentUserId);
              debugPrint('PLACE_ORDER: Reading user usage: ${userUsageRef.path}');
              await transaction.get(userUsageRef);
            }
          } else {
            debugPrint('PLACE_ORDER: Coupon $couponCode does not exist in Firestore');
          }
        } else {
          debugPrint('PLACE_ORDER: No coupon code provided, skipping coupon reads.');
        }

        // ─── ALL WRITES AFTER ───────────────────────
        // 1. Lưu thông tin đơn hàng
        try {
          debugPrint('PLACE_ORDER: Writing order document to ${orderRef.path}');
          transaction.set(orderRef, order.toMap());
        } catch (e) {
          debugPrint('PLACE_ORDER_ERROR: Writing order failed: $e');
          rethrow;
        }

        // 2. Tăng số lượt sử dụng mã giảm giá nếu có
        if (couponSnap != null && couponSnap.exists) {
          final couponRef = _db.collection(FirestoreCollections.coupons).doc(couponCode);
          try {
            final couponData = couponSnap.data() as Map<String, dynamic>?;
            final currentUsed = (couponData?['usedCount'] ?? 0) as int;
            debugPrint('PLACE_ORDER: Updating usedCount for coupon $couponCode');
            transaction.update(couponRef, {'usedCount': currentUsed + 1});
          } catch (e) {
            debugPrint('PLACE_ORDER_ERROR: Updating coupon count failed: $e');
            rethrow;
          }

          // 3. Record per-user usage if perUserLimit > 0
          final perUserLimit = (couponSnap.data() as Map<String, dynamic>?)?['perUserLimit'] as int? ?? 0;
          if (perUserLimit > 0 && currentUserId != null) {
            final userUsageRef = _db
                .collection(FirestoreCollections.coupons)
                .doc(couponCode)
                .collection('usedBy')
                .doc(currentUserId);
            try {
              debugPrint('PLACE_ORDER: Writing user usage to ${userUsageRef.path}');
              transaction.set(userUsageRef, {
                'usedAt': FieldValue.serverTimestamp(),
              });
            } catch (e) {
              debugPrint('PLACE_ORDER_ERROR: Writing user usage failed: $e');
              rethrow;
            }
          }
        }
      });

      _lastPlacedOrder = order;
      notifyListeners();
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

  /// Lấy stream của một đơn hàng cụ thể để cập nhật UI realtime
  Stream<Order> getOrderStream(String orderId) {
    return _db
        .collection(FirestoreCollections.orders)
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Đơn hàng không tồn tại');
      }
      return Order.fromMap(snapshot.data()!);
    });
  }

  /// Cập nhật trạng thái đơn hàng (Admin) và gửi thông báo cho khách
  Future<String?> updateOrderStatus(String orderId, OrderStatus nextStatus) async {
    try {
      final orderRef = _db.collection(FirestoreCollections.orders).doc(orderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) return 'Không tìm thấy đơn hàng';

      final userId = orderSnap.data()?['userId'] as String?;
      if (userId == null) return 'Không tìm thấy thông tin khách hàng';

      await orderRef.update({'status': nextStatus.name});

      // Gửi thông báo dựa trên trạng thái mới
      String? title;
      String? body;

      switch (nextStatus) {
        case OrderStatus.confirmed:
          title = 'Đơn hàng đã được xác nhận ✅';
          body = 'Đơn hàng của bạn đang được chuẩn bị 🍳';
          break;
        case OrderStatus.delivering:
          title = 'Đơn hàng đang được giao 🛵';
          body = 'Tài xế đang trên đường đến bạn!';
          break;
        case OrderStatus.completed:
          title = 'Đơn hàng đã giao thành công 🎉';
          body = 'Cảm ơn bạn! Hãy đánh giá món ăn nhé ⭐';
          break;
        case OrderStatus.cancelled:
          title = 'Đơn hàng đã bị huỷ ❌';
          body = 'Đơn hàng của bạn đã bị huỷ';
          break;
        default:
          break;
      }

      if (title != null && body != null) {
        await NotificationProvider.createNotification(
          userId: userId,
          type: 'order_status',
          title: title,
          body: body,
          orderId: orderId,
        );
      }

      return null;
    } catch (e) {
      return 'Lỗi cập nhật: $e';
    }
  }

  /// Hủy đơn hàng (chỉ khi đang ở trạng thái pending)
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final orderRef = _db
          .collection(FirestoreCollections.orders)
          .doc(orderId);

      final orderSnapBefore = await orderRef.get();
      final userId = orderSnapBefore.data()?['userId'] as String?;

      final result = await _db.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) return false;
        final data = orderSnap.data()!;
        final currentStatus = data['status'] as String;
        final couponCode = data['couponCode'] as String?;
        if (currentStatus != OrderStatus.pending.name) return false;
        transaction.update(orderRef, {
          'status': OrderStatus.cancelled.name,
          'cancelledAt': Timestamp.now(),
          'cancelReason': reason,
        });
        if (couponCode != null && couponCode.isNotEmpty) {
          final couponRef = _db
              .collection(FirestoreCollections.coupons)
              .doc(couponCode);
          final couponSnap = await transaction.get(couponRef);
          if (couponSnap.exists) {
            final couponData = couponSnap.data() as Map<String, dynamic>?;
            final currentUsed = (couponData?['usedCount'] ?? 0) as int;
            if (currentUsed > 0) {
              transaction.update(couponRef, {'usedCount': currentUsed - 1});
            }
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId != null) {
              final userUsageRef = _db
                  .collection(FirestoreCollections.coupons)
                  .doc(couponCode)
                  .collection('usedBy')
                  .doc(currentUserId);
              transaction.delete(userUsageRef);
            }
          }
        }
        return true;
      });

      if (result && userId != null) {
        await NotificationProvider.createNotification(
          userId: userId,
          type: 'order_status',
          title: 'Đơn hàng đã bị huỷ ❌',
          body: 'Đơn hàng của bạn đã bị huỷ',
          orderId: orderId,
        );
      }
      return result;
    } catch (e) {
      debugPrint('Lỗi hủy đơn hàng: $e');
      return false;
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
    _lastPlacedOrder = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}
