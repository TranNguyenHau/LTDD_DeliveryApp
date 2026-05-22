// lib/screens/history_screen.dart
// Lịch sử đơn hàng đã hoàn thành — tổng chi tiêu, xem chi tiết

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';
import 'review_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Map<String, Future<bool>> _reviewedCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOrdersLoaded());
  }

  Future<void> _ensureOrdersLoaded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await context.read<OrderProvider>().bindUser(uid);
  }

  Future<bool> _getReviewedFuture(String foodId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = '${uid}_$foodId';
    return _reviewedCache.putIfAbsent(
      key,
      () => context.read<ReviewProvider>().hasUserReviewedFood(uid, foodId),
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final completed = orderProvider.completedOrders;
    final totalSpent = orderProvider.totalSpent;
    final primary = Theme.of(context).primaryColor;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Lịch sử'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: orderProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            )
          : Column(
              children: [
                // Tổng chi tiêu
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng đã chi tiêu',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatPrice(totalSpent)}đ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${completed.length} đơn đã hoàn thành',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: completed.isEmpty
                      ? Center(
                          child: Text(
                            orderProvider.errorMessage ??
                                'Chưa có đơn hàng hoàn thành',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFFF6B35),
                          onRefresh: () async {
                            _reviewedCache.clear();
                            await _ensureOrdersLoaded();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: completed.length,
                            itemBuilder: (ctx, i) {
                              final order = completed[i];
                              return Column(
                                children: [
                                  OrderCard(
                                    order: order,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrderDetailScreen(orderId: order.id),
                                      ),
                                    ),
                                  ),
                                  // Nút đánh giá cho từng món trong đơn hàng
                                  Transform.translate(
                                    offset: const Offset(0, -8),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(height: 1),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Đánh giá món ăn',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...order.items.map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.food.name,
                                                      style: const TextStyle(fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  FutureBuilder<bool>(
                                                    future: _getReviewedFuture(item.food.id),
                                                    builder: (context, snapshot) {
                                                      final hasReviewed =
                                                          snapshot.data ?? false;

                                                      if (hasReviewed) {
                                                        return const Text(
                                                          'Đã đánh giá ✓',
                                                          style: TextStyle(
                                                            color: Color(0xFF22C55E),
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        );
                                                      }

                                                      return TextButton(
                                                        onPressed: () => Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => ReviewScreen(
                                                                food: item.food),
                                                          ),
                                                        ).then((_) {
                                                          final uidStr = FirebaseAuth.instance.currentUser?.uid ?? '';
                                                          _reviewedCache.remove('${uidStr}_${item.food.id}');
                                                          setState(() {});
                                                        }),
                                                        style: TextButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 12, vertical: 4),
                                                          minimumSize: Size.zero,
                                                          tapTargetSize:
                                                              MaterialTapTargetSize.shrinkWrap,
                                                          backgroundColor:
                                                              const Color(0xFFFF6B00)
                                                                  .withOpacity(0.1),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(20),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Đánh giá',
                                                          style: TextStyle(
                                                            color: Color(0xFFFF6B00),
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
