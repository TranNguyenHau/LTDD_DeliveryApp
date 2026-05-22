// lib/providers/coupon_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/coupon.dart';
import '../models/cart_item.dart';

class CouponResult {
  final Coupon? coupon;
  final String? errorMessage;

  CouponResult({this.coupon, this.errorMessage});

  bool get isSuccess => coupon != null;
}

class CouponProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Coupon? _appliedCoupon;
  bool _isValidating = false;

  // New states for Shopee-style selection
  List<Coupon> _availableCoupons = [];
  Coupon? _suggestedCoupon;
  bool _isLoadingAvailable = false;

  Coupon? get appliedCoupon => _appliedCoupon;
  bool get isValidating => _isValidating;
  List<Coupon> get availableCoupons => _availableCoupons;
  Coupon? get suggestedCoupon => _suggestedCoupon;
  bool get isLoadingAvailable => _isLoadingAvailable;

  /// Tính số tiền giảm giá dựa trên giỏ hàng
  double calculateDiscount(double cartTotal) {
    if (_appliedCoupon == null) return 0.0;
    return _calculateValue(_appliedCoupon!, cartTotal);
  }

  double _calculateValue(Coupon c, double total) {
    double discount = 0.0;
    if (c.discountType == 'percentage') {
      discount = total * (c.discountValue / 100);
      if (c.maxDiscount > 0 && discount > c.maxDiscount) {
        discount = c.maxDiscount;
      }
    } else {
      discount = c.discountValue;
    }
    return discount;
  }

  /// Lấy danh sách mã giảm giá có thể áp dụng cho giỏ hàng
  Future<void> fetchAvailableCoupons(double cartTotal) async {
    _isLoadingAvailable = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection(FirestoreCollections.coupons)
          .where('isActive', isEqualTo: true)
          .get();

      final now = DateTime.now();
      List<Coupon> allCoupons = snapshot.docs
          .map((doc) => Coupon.fromFirestore(doc))
          .toList();

      // Lọc mã hợp lệ: HSD, Lượt dùng, và Giá trị đơn tối thiểu
      final initialFiltered = allCoupons.where((c) {
        return c.expiryDate.isAfter(now) &&
               c.usedCount < c.usageLimit &&
               c.minOrderValue <= cartTotal;
      }).toList();

      // Per-user check: if perUserLimit > 0, exclude coupons already used by current user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final List<Future<bool>> checkFutures = initialFiltered.map((coupon) async {
          if (coupon.perUserLimit <= 0) return true;
          final userDoc = await _db
              .collection(FirestoreCollections.coupons)
              .doc(coupon.code)
              .collection('usedBy')
              .doc(userId)
              .get();
          return !userDoc.exists;
        }).toList();

        final results = await Future.wait(checkFutures);
        _availableCoupons = [];
        for (int i = 0; i < initialFiltered.length; i++) {
          if (results[i]) {
            _availableCoupons.add(initialFiltered[i]);
          }
        }
      } else {
        _availableCoupons = initialFiltered;
      }

      // Sắp xếp: Ưu tiên mã có giá trị giảm cao nhất cho đơn hiện tại
      _availableCoupons.sort((a, b) {
        double valA = _calculateValue(a, cartTotal);
        double valB = _calculateValue(b, cartTotal);
        return valB.compareTo(valA); 
      });

      _suggestedCoupon = _availableCoupons.isNotEmpty ? _availableCoupons.first : null;
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
    } finally {
      _isLoadingAvailable = false;
      notifyListeners();
    }
  }

  /// Áp dụng trực tiếp một đối tượng Coupon (sau khi đã validate cơ bản ở client)
  void applyCoupon(Coupon coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  /// Kiểm tra mã giảm giá từ Firestore (giữ lại logic cũ cho nhập tay)
  Future<CouponResult> validateCoupon(String code, double cartTotal, List<CartItem> cartItems) async {
    _isValidating = true;
    notifyListeners();

    try {
      final doc = await _db.collection(FirestoreCollections.coupons).doc(code).get();

      if (!doc.exists) {
        return CouponResult(errorMessage: 'Mã giảm giá không tồn tại');
      }

      final coupon = Coupon.fromFirestore(doc);

      if (!coupon.isActive) {
        return CouponResult(errorMessage: 'Mã giảm giá không còn hoạt động');
      }

      if (DateTime.now().isAfter(coupon.expiryDate)) {
        return CouponResult(errorMessage: 'Mã giảm giá đã hết hạn');
      }

      if (coupon.usedCount >= coupon.usageLimit) {
        return CouponResult(errorMessage: 'Mã đã hết lượt sử dụng');
      }

      // Kiểm tra danh mục áp dụng (nếu có)
      if (coupon.applicableCategoryIds != null && coupon.applicableCategoryIds!.isNotEmpty) {
        bool isApplicable = cartItems.any((item) => coupon.applicableCategoryIds!.contains(item.food.categoryId));
        if (!isApplicable) {
          return CouponResult(errorMessage: 'Mã không áp dụng cho sản phẩm này');
        }
      }

      if (cartTotal < coupon.minOrderValue) {
        final formatVal = coupon.minOrderValue.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        return CouponResult(errorMessage: 'Đơn hàng tối thiểu ${formatVal}đ để dùng mã này');
      }

      // Per-user check AFTER existing validations
      if (coupon.perUserLimit > 0) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final userDoc = await _db
              .collection(FirestoreCollections.coupons)
              .doc(code)
              .collection('usedBy')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            return CouponResult(errorMessage: 'Bạn đã sử dụng mã giảm giá này rồi');
          }
        }
      }

      _appliedCoupon = coupon;
      return CouponResult(coupon: coupon);
    } catch (e) {
      return CouponResult(errorMessage: 'Lỗi kiểm tra mã: $e');
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  /// Tăng số lượt sử dụng mã (gọi khi đặt hàng thành công)
  Future<void> useCoupon(String code) async {
    final docRef = _db.collection(FirestoreCollections.coupons).doc(code);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      int newUsedCount = (snapshot.data()?['usedCount'] ?? 0) + 1;
      transaction.update(docRef, {'usedCount': newUsedCount});
    });
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  void clear() {
    _appliedCoupon = null;
    _availableCoupons = [];
    _suggestedCoupon = null;
    _isValidating = false;
    _isLoadingAvailable = false;
    notifyListeners();
  }
}
