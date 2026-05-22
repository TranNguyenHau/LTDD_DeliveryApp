// lib/screens/admin/admin_stats_screen.dart
// Màn hình thống kê dành cho Admin — không dùng package chart ngoài

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:food_app/constants/firestore_collections.dart';
import 'package:food_app/models/order.dart';

// ─────────────────────────────────────────────────────────────
// Data helpers
// ─────────────────────────────────────────────────────────────

class _FoodStat {
  final String name;
  int qty;
  double revenue;
  _FoodStat({required this.name, this.qty = 0, this.revenue = 0});
}

class _StatsData {
  final List<Order> orders;

  _StatsData(this.orders);

  List<Order> get done =>
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  double get totalRevenue => done.fold(0.0, (s, o) => s + o.totalAmount);

  double revenueFor(DateTime day) {
    return done
        .where((o) =>
            o.createdAt.year == day.year &&
            o.createdAt.month == day.month &&
            o.createdAt.day == day.day)
        .fold(0.0, (s, o) => s + o.totalAmount);
  }

  double revenueInRange(DateTime from, DateTime to) {
    return done
        .where((o) =>
            o.createdAt.isAfter(from.subtract(const Duration(seconds: 1))) &&
            o.createdAt.isBefore(to.add(const Duration(seconds: 1))))
        .fold(0.0, (s, o) => s + o.totalAmount);
  }

  int ordersInRange(DateTime from, DateTime to) {
    return orders
        .where((o) =>
            o.createdAt.isAfter(from.subtract(const Duration(seconds: 1))) &&
            o.createdAt.isBefore(to.add(const Duration(seconds: 1))))
        .length;
  }

  double get avgOrderValue {
    if (done.isEmpty) return 0;
    return totalRevenue / done.length;
  }

  // Top foods by quantity sold
  List<_FoodStat> get topFoods {
    final map = <String, _FoodStat>{};
    for (final o in done) {
      for (final item in o.items) {
        final key = item.food.id.isEmpty ? item.food.name : item.food.id;
        map.putIfAbsent(key, () => _FoodStat(name: item.food.name));
        map[key]!.qty += item.quantity;
        map[key]!.revenue += item.food.price * item.quantity;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    return list.take(6).toList();
  }

  // Revenue by category
  Map<String, double> get revenueByCategory {
    final map = <String, double>{};
    for (final o in done) {
      for (final item in o.items) {
        final cat = item.food.categoryId;
        map[cat] = (map[cat] ?? 0) + item.food.price * item.quantity;
      }
    }
    return map;
  }

  // Order count by status
  Map<OrderStatus, int> get countByStatus {
    final map = <OrderStatus, int>{};
    for (final o in orders) {
      map[o.status] = (map[o.status] ?? 0) + 1;
    }
    return map;
  }

  // Peak hours (0-23)
  Map<int, int> get ordersByHour {
    final map = <int, int>{};
    for (final o in orders) {
      final h = o.createdAt.hour;
      map[h] = (map[h] ?? 0) + 1;
    }
    return map;
  }

  int get peakHour {
    if (ordersByHour.isEmpty) return -1;
    return ordersByHour.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // ─── Palette ────────────────────────────────────────────────
  static const _bg        = Color(0xFF0F172A);
  static const _surface   = Color(0xFF1E293B);
  static const _card      = Color(0xFF1A2744);
  static const _accent    = Color(0xFF3B82F6);
  static const _accentEnd = Color(0xFF6366F1);
  static const _green     = Color(0xFF10B981);
  static const _yellow    = Color(0xFFF59E0B);
  static const _purple    = Color(0xFFA855F7);
  static const _red       = Color(0xFFEF4444);
  static const _text      = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border    = Color(0xFF2D3F5C);

  StreamSubscription? _sub;
  List<Order> _orders = [];
  bool _loading = true;

  // Kỳ thống kê đang chọn: 7 | 30 | 90
  int _days = 7;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      setState(() {
        _orders = snap.docs.map((d) => Order.fromMap(d.data())).toList();
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}K';
    }
    return v.toInt().toString();
  }

  String _fmtFull(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: _days - 1));

    final all = _StatsData(_orders);
    final rangeOrders = _orders
        .where((o) =>
            o.createdAt.isAfter(
                rangeStart.subtract(const Duration(seconds: 1))))
        .toList();
    final range = _StatsData(rangeOrders);

    // 7 days bar data
    final barDays = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final barValues = barDays.map((d) => all.revenueFor(d)).toList();
    final maxBar = barValues.fold(0.0, math.max);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : RefreshIndicator(
              color: _accent,
              backgroundColor: _surface,
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // ── Kỳ lọc ────────────────────────────────
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),

                  // ── KPI cards ──────────────────────────────
                  _buildKpiRow(range, rangeStart, today),
                  const SizedBox(height: 20),

                  // ── Biểu đồ doanh thu 7 ngày ───────────────
                  _sectionTitle('Doanh thu 7 ngày qua', Icons.bar_chart_rounded),
                  const SizedBox(height: 12),
                  _buildBarChart(barDays, barValues, maxBar),
                  const SizedBox(height: 20),

                  // ── Top món bán chạy ───────────────────────
                  _sectionTitle('Top món bán chạy', Icons.emoji_food_beverage_rounded),
                  const SizedBox(height: 12),
                  _buildTopFoods(all.topFoods),
                  const SizedBox(height: 20),

                  // ── Tỉ lệ đơn theo trạng thái ─────────────
                  _sectionTitle('Trạng thái đơn hàng', Icons.donut_large_rounded),
                  const SizedBox(height: 12),
                  _buildStatusBreakdown(all.countByStatus, _orders.length),
                  const SizedBox(height: 20),

                  // ── Doanh thu theo danh mục ────────────────
                  _sectionTitle('Doanh thu theo danh mục', Icons.category_rounded),
                  const SizedBox(height: 12),
                  _buildCategoryChart(all.revenueByCategory),
                  const SizedBox(height: 20),

                  // ── Giờ cao điểm ───────────────────────────
                  _sectionTitle('Giờ cao điểm', Icons.schedule_rounded),
                  const SizedBox(height: 12),
                  _buildPeakHours(all.ordersByHour),
                  const SizedBox(height: 20),

                  // ── Tổng quan tích lũy ─────────────────────
                  _sectionTitle('Tổng quan tích lũy', Icons.analytics_rounded),
                  const SizedBox(height: 12),
                  _buildOverallSummary(all),
                ],
              ),
            ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thống kê',
            style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      );

  // ─── Period selector ────────────────────────────────────────
  Widget _buildPeriodSelector() {
    final opts = [
      (7, '7 ngày'),
      (30, '30 ngày'),
      (90, '3 tháng'),
    ];
    return Row(
      children: opts.map((o) {
        final (days, label) = o;
        final sel = _days == days;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _days = days),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: o != opts.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(colors: [_accent, _accentEnd])
                    : null,
                color: sel ? null : _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? Colors.transparent : _border),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sel ? Colors.white : _textMuted,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── KPI row ─────────────────────────────────────────────────
  Widget _buildKpiRow(_StatsData range, DateTime from, DateTime to) {
    final todayData = _StatsData(_orders);
    final todayRevenue = todayData.revenueFor(to);
    final todayOrders = _orders
        .where((o) =>
            o.createdAt.year == to.year &&
            o.createdAt.month == to.month &&
            o.createdAt.day == to.day)
        .length;

    return Column(
      children: [
        // Row 1: Doanh thu kỳ + Hôm nay
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_rounded,
                iconColor: _green,
                label: 'Doanh thu $_days ngày',
                value: '${_fmt(range.totalRevenue)} đ',
                sub: '${range.done.length} đơn hoàn thành',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.today_rounded,
                iconColor: _yellow,
                label: 'Hôm nay',
                value: '${_fmt(todayRevenue)} đ',
                sub: '$todayOrders đơn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: TB đơn + Tổng đơn kỳ
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.receipt_long_rounded,
                iconColor: _purple,
                label: 'Giá trị TB/đơn',
                value: '${_fmt(range.avgOrderValue)} đ',
                sub: 'Đơn hoàn thành',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.shopping_bag_rounded,
                iconColor: _accent,
                label: 'Tổng đơn kỳ',
                value: range.ordersInRange(from, to).toString(),
                sub: 'Mọi trạng thái',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Section title ───────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accent, size: 17),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      );

  // ─── Bar chart 7 ngày ────────────────────────────────────────
  Widget _buildBarChart(
      List<DateTime> days, List<double> values, double maxVal) {
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final weekdayLabels = {1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'};

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final val = values[i];
                final frac = maxVal > 0 ? val / maxVal : 0.0;
                final isToday = days[i].day == DateTime.now().day &&
                    days[i].month == DateTime.now().month;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            _fmt(val),
                            style: TextStyle(
                              color: isToday ? _yellow : _textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutQuart,
                          height: math.max(frac * 120, val > 0 ? 4 : 0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [_yellow, const Color(0xFFFDE68A)]
                                  : [_accent, _accentEnd],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weekdayLabels[days[i].weekday] ?? '',
                          style: TextStyle(
                            color: isToday ? _yellow : _textMuted,
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        Text(
                          '${days[i].day}',
                          style: TextStyle(
                            color: isToday ? _yellow : _textMuted.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _dot(_accent),
              const SizedBox(width: 6),
              const Text('Ngày thường',
                  style: TextStyle(color: _textMuted, fontSize: 11)),
              const SizedBox(width: 16),
              _dot(_yellow),
              const SizedBox(width: 6),
              const Text('Hôm nay',
                  style: TextStyle(color: _textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  // ─── Top foods ───────────────────────────────────────────────
  Widget _buildTopFoods(List<_FoodStat> foods) {
    if (foods.isEmpty) {
      return _emptyCard('Chưa có dữ liệu món ăn');
    }
    final maxQty = foods.first.qty.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(foods.length, (i) {
          final f = foods[i];
          final frac = maxQty > 0 ? f.qty / maxQty : 0.0;
          final colors = [_accent, _green, _yellow, _purple, _red, _accentEnd];
          final color = colors[i % colors.length];
          final isLast = i == foods.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < 3
                            ? color.withOpacity(0.2)
                            : _border.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i < 3 ? color : _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name,
                              style: const TextStyle(
                                  color: _text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: frac,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${f.qty} phần',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text('${_fmt(f.revenue)} đ',
                            style: const TextStyle(
                                color: _textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: _border.withOpacity(0.5)),
            ],
          );
        }),
      ),
    );
  }

  // ─── Status breakdown ─────────────────────────────────────────
  Widget _buildStatusBreakdown(Map<OrderStatus, int> counts, int total) {
    if (total == 0) return _emptyCard('Chưa có đơn hàng nào');

    final items = [
      (OrderStatus.pending,   'Chờ xác nhận', _yellow),
      (OrderStatus.confirmed, 'Đã nhận',      _accent),
      (OrderStatus.preparing, 'Đang làm',     _purple),
      (OrderStatus.delivered, 'Hoàn thành',   _green),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Mini donut (custom paint)
          SizedBox(
            height: 120,
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: items.map((i) {
                        final c = counts[i.$1] ?? 0;
                        return c.toDouble();
                      }).toList(),
                      colors: items.map((i) => i.$3).toList(),
                      total: total.toDouble(),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$total',
                              style: const TextStyle(
                                  color: _text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const Text('đơn',
                              style: TextStyle(
                                  color: _textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: items.map((item) {
                      final (status, label, color) = item;
                      final cnt = counts[status] ?? 0;
                      final pct = total > 0 ? (cnt / total * 100) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(label,
                                  style: const TextStyle(
                                      color: _textMuted, fontSize: 12)),
                            ),
                            Text(
                              '$cnt (${pct.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category chart (horizontal bars) ───────────────────────
  Widget _buildCategoryChart(Map<String, double> data) {
    if (data.isEmpty) return _emptyCard('Chưa có dữ liệu danh mục');

    final catNames = {
      'monchinh':   '🍚 Món chính',
      'khaivi':     '🥗 Khai vị',
      'trangmieng': '🍮 Tráng miệng',
      'douong':     '🥤 Đồ uống',
    };
    final catColors = {
      'monchinh':   _accent,
      'khaivi':     _green,
      'trangmieng': _yellow,
      'douong':     _purple,
    };

    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.isNotEmpty ? entries.first.value : 1.0;
    final totalCatRev = entries.fold(0.0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: entries.map((e) {
          final frac = maxVal > 0 ? e.value / maxVal : 0.0;
          final pct = totalCatRev > 0 ? e.value / totalCatRev * 100 : 0.0;
          final color = catColors[e.key] ?? _accent;
          final name = catNames[e.key] ?? e.key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Text(
                      '${_fmt(e.value)} đ  (${pct.toStringAsFixed(0)}%)',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(
                          height: 8,
                          color: _border),
                      FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.6)]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Peak hours ──────────────────────────────────────────────
  Widget _buildPeakHours(Map<int, int> data) {
    if (data.isEmpty) return _emptyCard('Chưa có dữ liệu giờ');

    final maxCount = data.values.fold(0, math.max).toDouble();
    // Hiển thị khung giờ 6h → 22h
    final hours = List.generate(17, (i) => i + 6);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hours.map((h) {
                final cnt = data[h] ?? 0;
                final frac = maxCount > 0 ? cnt / maxCount : 0.0;
                final isPeak = data.isNotEmpty &&
                    cnt ==
                        data.values.fold(0, math.max) &&
                    cnt > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: math.max(frac * 56, cnt > 0 ? 3 : 0),
                          decoration: BoxDecoration(
                            color: isPeak ? _yellow : _accent.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          h % 3 == 0 ? '$h' : '',
                          style: TextStyle(
                            color: isPeak ? _yellow : _textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (data.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: _yellow, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Cao điểm: ${_peakLabel(data)} — ${data.values.fold(0, math.max)} đơn',
                  style: const TextStyle(
                      color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _peakLabel(Map<int, int> data) {
    if (data.isEmpty) return '--';
    final peak = data.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return '${peak}:00 – ${peak + 1}:00';
  }

  // ─── Overall summary ─────────────────────────────────────────
  Widget _buildOverallSummary(_StatsData all) {
    final items = [
      (Icons.monetization_on_rounded, _green,  'Tổng doanh thu',    '${_fmtFull(all.totalRevenue)} đ'),
      (Icons.receipt_rounded,         _accent, 'Tổng đơn',          '${_orders.length}'),
      (Icons.check_circle_rounded,    _green,  'Đơn hoàn thành',    '${all.done.length}'),
      (Icons.pending_rounded,         _yellow, 'Đơn đang xử lý',    '${_orders.length - all.done.length}'),
      (Icons.analytics_rounded, _purple, 'Giá trị TB/đơn', '${_fmtFull(all.avgOrderValue)} đ'),
      (Icons.star_rounded,            _yellow, 'Món bán chạy nhất', all.topFoods.isNotEmpty ? all.topFoods.first.name : '--'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final (icon, color, label, value) = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              color: _textMuted, fontSize: 13)),
                    ),
                    Text(value,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: _border.withOpacity(0.5)),
            ],
          );
        }),
      ),
    );
  }

  Widget _emptyCard(String msg) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text(msg,
              style: const TextStyle(color: _textMuted, fontSize: 14)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// KPI Card widget
// ─────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  static const _card      = Color(0xFF1A2744);
  static const _border    = Color(0xFF2D3F5C);
  static const _text      = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: iconColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(sub,
              style:
                  const TextStyle(color: _textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Donut chart painter
// ─────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double total;

  _DonutPainter(
      {required this.values, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 18.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Background circle
    paint.color = const Color(0xFF2D3F5C);
    canvas.drawCircle(center, radius, paint);

    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = (values[i] / (total > 0 ? total : 1)) * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.total != total;
}