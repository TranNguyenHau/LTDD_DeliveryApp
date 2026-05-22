// lib/providers/notification_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<AppNotification> _notifications = [];
  StreamSubscription? _sub;
  String? _userId;

  List<AppNotification> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Lắng nghe thông báo realtime cho user
  Future<void> loadNotifications(String userId) async {
    if (_userId == userId && _sub != null) return;
    
    await _sub?.cancel();
    _userId = userId;
    
    _sub = _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .toList();
      notifyListeners();
    });
  }

  /// Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String userId, String notifId) async {
    try {
      await _db
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notifId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final unreadDocs = await _db
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Helper static để tạo thông báo mới từ bất kỳ đâu
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? orderId,
    String? reviewId,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc();

      final notif = AppNotification(
        id: docRef.id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        orderId: orderId,
        reviewId: reviewId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(notif.toMap());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
