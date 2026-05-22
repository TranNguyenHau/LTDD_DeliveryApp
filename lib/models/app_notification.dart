// lib/models/app_notification.dart
// Thông báo hệ thống lưu trên collection notifications/{userId}/items

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type; // 'order_status' | 'admin_reply'
  final String title;
  final String body;
  final String? orderId;
  final String? reviewId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.reviewId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'orderId': orderId,
      'reviewId': reviewId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'order_status',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      orderId: map['orderId'] as String?,
      reviewId: map['reviewId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      reviewId: reviewId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
