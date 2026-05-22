// lib/screens/history_screen.dart
// Lịch sử đơn hàng đã hoàn thành — tổng chi tiêu, xem chi tiết

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
                          onRefresh: _ensureOrdersLoaded,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: completed.length,
                            itemBuilder: (ctx, i) {
                              final order = completed[i];
                              return OrderCard(
                                order: order,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailScreen(orderId: order.id),
                                  ),
                                ),
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
