// lib/models/coupon.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String code;
  final String discountType; // "percentage" | "fixed"
  final double discountValue;
  final double minOrderValue;
  final double maxDiscount;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final List<String>? applicableCategoryIds;
  final int perUserLimit;

  Coupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    this.applicableCategoryIds,
    this.perUserLimit = 0,
  });

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Coupon(
      code: doc.id,
      discountType: data['discountType'] ?? 'fixed',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (data['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble() ?? 0.0,
      expiryDate: _parseDateTime(data['expiryDate']) ?? DateTime.now(),
      usageLimit: data['usageLimit'] ?? 0,
      usedCount: data['usedCount'] ?? 0,
      isActive: data['isActive'] ?? false,
      applicableCategoryIds: data['applicableCategoryIds'] != null 
          ? List<String>.from(data['applicableCategoryIds']) 
          : null,
      perUserLimit: (data['perUserLimit'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      'applicableCategoryIds': applicableCategoryIds,
      'perUserLimit': perUserLimit,
    };
  }

  Coupon copyWith({
    String? code,
    String? discountType,
    double? discountValue,
    double? minOrderValue,
    double? maxDiscount,
    DateTime? expiryDate,
    int? usageLimit,
    int? usedCount,
    bool? isActive,
    List<String>? applicableCategoryIds,
    int? perUserLimit,
  }) {
    return Coupon(
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      applicableCategoryIds: applicableCategoryIds ?? this.applicableCategoryIds,
      perUserLimit: perUserLimit ?? this.perUserLimit,
    );
  }
}
