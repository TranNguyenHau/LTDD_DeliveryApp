// lib/providers/review_provider.dart
// Đọc/ghi đánh giá theo foodId — tính rating trung bình

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/order.dart';
import '../models/review.dart';

class ReviewProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _foodId;
  List<Review> _reviews = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewsSub;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Review> get reviews => List.unmodifiable(_reviews);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Rating trung bình từ danh sách đánh giá hiện tại
  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / _reviews.length;
  }

  int get reviewCount => _reviews.length;

  /// Lắng nghe đánh giá realtime theo món ăn
  Future<void> loadReviewsForFood(String foodId) async {
    if (_foodId == foodId && _reviewsSub != null) return;

    await _reviewsSub?.cancel();
    _foodId = foodId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _reviewsSub = _db
        .collection(FirestoreCollections.reviews)
        .where('foodId', isEqualTo: foodId)
        .snapshots()
        .listen(
      (snap) {
        _reviews = snap.docs
            .map((d) => Review.fromMap(d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Không tải được đánh giá: $e';
        notifyListeners();
      },
    );
  }

  /// User đã đánh giá món này chưa
  bool hasUserReviewed(String userId) {
    return _reviews.any((r) => r.userId == userId);
  }

  /// Kiểm tra đã mua món (có trong đơn hàng của user)
  static bool hasPurchasedFood(String foodId, List<Order> orders) {
    return orders.any(
      (o) => o.items.any((item) => item.food.id == foodId),
    );
  }

  /// Có thể đánh giá: đã mua và chưa đánh giá
  bool canUserReview({
    required String userId,
    required String foodId,
    required List<Order> orders,
  }) {
    return hasPurchasedFood(foodId, orders) && !hasUserReviewed(userId);
  }

  /// Gửi đánh giá mới lên Firestore
  Future<String?> submitReview({
    required String userId,
    required String userName,
    required String foodId,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      return 'Vui lòng chọn từ 1 đến 5 sao';
    }
    if (hasUserReviewed(userId)) {
      return 'Bạn đã đánh giá món này rồi';
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final reviewId = '${userId}_$foodId';
      final review = Review(
        id: reviewId,
        userId: userId,
        foodId: foodId,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
        userName: userName,
      );

      await _db
          .collection(FirestoreCollections.reviews)
          .doc(reviewId)
          .set(review.toMap());

      // Cập nhật rating trung bình lên document món ăn
      await _syncFoodRating(foodId);

      return null;
    } catch (e) {
      return 'Gửi đánh giá thất bại: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Đồng bộ rating/reviewCount lên collection foods
  Future<void> _syncFoodRating(String foodId) async {
    final snap = await _db
        .collection(FirestoreCollections.reviews)
        .where('foodId', isEqualTo: foodId)
        .get();

    if (snap.docs.isEmpty) return;

    final list =
        snap.docs.map((d) => Review.fromMap(d.data())).toList();
    final avg = list.fold<int>(0, (s, r) => s + r.rating) / list.length;

    await _db.collection(FirestoreCollections.foods).doc(foodId).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': list.length,
    });
  }

  Future<void> clear() async {
    await _reviewsSub?.cancel();
    _reviewsSub = null;
    _foodId = null;
    _reviews = [];
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    super.dispose();
  }
}
