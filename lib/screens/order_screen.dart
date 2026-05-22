// lib/screens/order_screen.dart
// Danh sách đơn hàng hiện tại — filter theo trạng thái, realtime Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  OrderFilter _filter = OrderFilter.all;

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

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.filteredActiveOrders(_filter);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Bộ lọc trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: _filter == OrderFilter.all,
                  onTap: () => setState(() => _filter = OrderFilter.all),
                ),
                _FilterChip(
                  label: 'Chờ xác nhận',
                  selected: _filter == OrderFilter.pending,
                  onTap: () => setState(() => _filter = OrderFilter.pending),
                ),
                _FilterChip(
                  label: 'Đã xác nhận',
                  selected: _filter == OrderFilter.confirmed,
                  onTap: () => setState(() => _filter = OrderFilter.confirmed),
                ),
                _FilterChip(
                  label: 'Đang giao',
                  selected: _filter == OrderFilter.delivering,
                  onTap: () => setState(() => _filter = OrderFilter.delivering),
                ),
              ],
            ),
          ),
          Expanded(
            child: orderProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  )
                : orders.isEmpty
                    ? _EmptyState(
                        message: orderProvider.errorMessage ??
                            'Không có đơn hàng nào',
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFFF6B35),
                        onRefresh: _ensureOrdersLoaded,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          itemBuilder: (ctx, i) {
                            final order = orders[i];
                            return OrderCard(
                              order: order,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(order: order),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? primary : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📦', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
