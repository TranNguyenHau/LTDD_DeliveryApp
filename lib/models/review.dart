// lib/models/review.dart
// Đánh giá sản phẩm trên collection "reviews"

import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String foodId;
  final String foodName;
  final int rating; // 1–5
  final String comment;
  final DateTime createdAt;
  final String userName;
  final String? adminReply;
  final DateTime? adminReplyAt;

  const Review({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.foodName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userName,
    this.adminReply,
    this.adminReplyAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodId': foodId,
      'foodName': foodName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'adminReply': adminReply,
      'adminReplyAt': adminReplyAt?.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      foodId: map['foodId'] as String? ?? '',
      foodName: map['foodName'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      userName: map['userName'] as String? ?? 'Khách',
      adminReply: map['adminReply'] as String?,
      adminReplyAt: _parseDateTime(map['adminReplyAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
