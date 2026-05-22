import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import '../../constants/firestore_collections.dart';
import '../../models/order.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF3B82F6);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);
  static const _danger = Color(0xFFEF4444);
  static const _success = Color(0xFF34D399);

  bool _isLoading = true;
  List<Order> _allOrders = [];
  Map<String, double> _revenueByDay = {};
  List<MapEntry<String, int>> _topFoods = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .get();

      _allOrders = snapshot.docs
          .map((doc) => Order.fromMap(doc.data()))
          .toList();

      // Process Revenue by Day (Last 7 days)
      _revenueByDay = {};
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('dd/MM').format(date);
        _revenueByDay[key] = 0;
      }

      Map<String, int> foodCounts = {};

      for (var order in _allOrders) {
        if (order.status == OrderStatus.completed) {
          final dateKey = DateFormat('dd/MM').format(order.createdAt);
          if (_revenueByDay.containsKey(dateKey)) {
            _revenueByDay[dateKey] = _revenueByDay[dateKey]! + order.totalAmount;
          }
        }

        // Count foods
        for (var item in order.items) {
          foodCounts[item.food.name] = (foodCounts[item.food.name] ?? 0) + item.quantity;
        }
      }

      _topFoods = foodCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topFoods = _topFoods.take(5).toList();

    } catch (e) {
      debugPrint("Stats Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedOrders = _allOrders.where((o) => o.status == OrderStatus.completed).toList();
    final cancelledOrders = _allOrders.where((o) => o.status == OrderStatus.cancelled).toList();
    final totalRevenue = completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final completionRate = _allOrders.isEmpty ? 0.0 : (completedOrders.length / _allOrders.length) * 100;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text("Thống kê doanh thu", style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _accent),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard("Doanh thu", "${NumberFormat.compact().format(totalRevenue)}đ", _success, Icons.payments),
                      _buildStatCard("Tổng đơn", _allOrders.length.toString(), _accent, Icons.shopping_cart),
                      _buildStatCard("Hoàn thành", completedOrders.length.toString(), Colors.blue, Icons.check_circle),
                      _buildStatCard("Đã hủy", cancelledOrders.length.toString(), _danger, Icons.cancel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    "Tỷ lệ hoàn thành",
                    "${completionRate.toStringAsFixed(1)}%",
                    Colors.orange,
                    Icons.analytics,
                    fullWidth: true
                  ),

                  const SizedBox(height: 24),
                  const Text("DOANH THU 7 NGÀY QUA", style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRevenueChart(),

                  const SizedBox(height: 24),
                  const Text("TOP 5 MÓN BÁN CHẠY", style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTopFoodsList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: _textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final maxRevenue = _revenueByDay.values.fold(0.0, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _revenueByDay.entries.map((e) {
                final heightFactor = maxRevenue > 0 ? e.value / maxRevenue : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: (heightFactor * 100).clamp(4, 100),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accent, Color(0xFF6366F1)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(e.key, style: const TextStyle(color: _textMuted, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
          if (maxRevenue > 0) ...[
            const Divider(color: _border, height: 24),
            Text(
              "Cao nhất: ${NumberFormat.decimalPattern().format(maxRevenue)}đ",
              style: const TextStyle(color: _textMuted, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTopFoodsList() {
    if (_topFoods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Center(child: Text("Chưa có dữ liệu", style: TextStyle(color: _textMuted))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: _topFoods.asMap().entries.map((entry) {
          final index = entry.key;
          final food = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: index == _topFoods.length - 1 ? null : const Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: index == 0 ? Colors.amber : _border,
                  child: Text("${index + 1}", style: TextStyle(color: index == 0 ? Colors.black : _text, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(food.key, style: const TextStyle(color: _text, fontWeight: FontWeight.w600))),
                Text("${food.value} lượt", style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
