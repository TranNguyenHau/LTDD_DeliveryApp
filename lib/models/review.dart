// lib/models/review.dart
// Đánh giá sản phẩm trên collection "reviews"

class Review {
  final String id;
  final String userId;
  final String foodId;
  final int rating; // 1–5
  final String comment;
  final DateTime createdAt;
  final String userName;

  const Review({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'foodId': foodId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      foodId: map['foodId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      userName: map['userName'] as String? ?? 'Khách',
    );
  }
}
