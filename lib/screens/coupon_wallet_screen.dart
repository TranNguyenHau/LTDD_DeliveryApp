// lib/screens/coupon_wallet_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/firestore_collections.dart';
import '../models/coupon.dart';
import '../widgets/coupon_card.dart';

class CouponWalletScreen extends StatefulWidget {
  const CouponWalletScreen({super.key});

  @override
  State<CouponWalletScreen> createState() => _CouponWalletScreenState();
}

class _CouponWalletScreenState extends State<CouponWalletScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Coupon> _coupons = [];
  Set<String> _usedCouponCodes = {};

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _db
          .collection(FirestoreCollections.coupons)
          .where('isActive', isEqualTo: true)
          .get();

      final allCoupons = snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList();
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final Set<String> usedCodes = {};
      
      if (userId != null) {
        // Efficiently check per-user usage limits for all fetched coupons
        final List<Future<String?>> checkFutures = allCoupons.map((coupon) async {
          if (coupon.perUserLimit <= 0) return null;
          final userDoc = await _db
              .collection(FirestoreCollections.coupons)
              .doc(coupon.code)
              .collection('usedBy')
              .doc(userId)
              .get();
          return userDoc.exists ? coupon.code : null;
        }).toList();

        final results = await Future.wait(checkFutures);
        for (var code in results) {
          if (code != null) usedCodes.add(code);
        }
      }

      if (mounted) {
        setState(() {
          _coupons = allCoupons;
          _usedCouponCodes = usedCodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Kho Voucher',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCoupons,
        color: const Color(0xFFFF6B00),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
            : _coupons.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = _coupons[index];
                      final isUsed = _usedCouponCodes.contains(coupon.code);

                      return CouponCard(
                        coupon: coupon,
                        isAvailable: !isUsed,
                        buttonText: isUsed ? 'Đã dùng' : 'Dùng ngay',
                        onApply: isUsed ? null : () {
                          // Quay về màn hình chính để đặt hàng
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa có voucher nào',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
