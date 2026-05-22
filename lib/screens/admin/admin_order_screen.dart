// lib/screens/admin/admin_order_screen.dart
// Quản lý đơn hàng dành cho Admin

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/constants/firestore_collections.dart';
import 'package:food_app/models/order.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen>
    with SingleTickerProviderStateMixin {
  // ─── Palette ────────────────────────────────────────────────
  static const _bg       = Color(0xFF0F172A);
  static const _surface  = Color(0xFF1E293B);
  static const _border   = Color(0xFF2D3F5C);
  static const _accent   = Color(0xFF3B82F6);
  static const _accentEnd= Color(0xFF6366F1);
  static const _text     = Colors.white;
  static const _textMuted= Color(0xFF94A3B8);

  // ─── Màu theo trạng thái ────────────────────────────────────
  static const _colorPending   = Color(0xFFF59E0B);
  static const _colorConfirmed = Color(0xFF3B82F6);
  static const _colorPreparing = Color(0xFFA855F7);
  static const _colorDone      = Color(0xFF10B981);

  late final TabController _tabCtrl;

  // Tabs: Chờ | Xác nhận | Đang làm | Hoàn thành
  static const _tabs = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.delivered,
  ];

  static const _tabLabels = [
    'Chờ xác nhận',
    'Đã nhận',
    'Đang làm',
    'Hoàn thành',
  ];

  // Realtime stream
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<Order> _allOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _startListening();
  }

  void _startListening() {
    _sub = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      setState(() {
        _allOrders =
            snap.docs.map((d) => Order.fromMap(d.data())).toList();
        _loading = false;
      });
    });
  }

  List<Order> _ordersForStatus(OrderStatus status) =>
      _allOrders.where((o) => o.status == status).toList();

  int _countOf(OrderStatus status) => _ordersForStatus(status).length;

  // ─── Đổi trạng thái đơn ─────────────────────────────────────
  Future<void> _updateStatus(Order order, OrderStatus newStatus) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .doc(order.id)
        .update({'status': newStatus.name});
  }

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStats(),
          _buildTabBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : TabBarView(
                    controller: _tabCtrl,
                    children: _tabs
                        .map((status) => _OrderList(
                              orders: _ordersForStatus(status),
                              status: status,
                              onUpdateStatus: _updateStatus,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Quản lý đơn hàng',
        style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: Text(
            '${_allOrders.length} đơn',
            style: const TextStyle(
                color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─── Stats row ───────────────────────────────────────────────
  Widget _buildStats() {
    final stats = [
      (_colorPending,   Icons.hourglass_top_rounded,  'Chờ',      _countOf(OrderStatus.pending)),
      (_colorConfirmed, Icons.check_circle_rounded,    'Đã nhận',  _countOf(OrderStatus.confirmed)),
      (_colorPreparing, Icons.restaurant_rounded,      'Đang làm', _countOf(OrderStatus.preparing)),
      (_colorDone,      Icons.done_all_rounded,        'Xong',     _countOf(OrderStatus.delivered)),
    ];

    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Row(
        children: stats.map((s) {
          final (color, icon, label, count) = s;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabCtrl.animateTo(stats.indexOf(s)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    Text(label,
                        style: const TextStyle(
                            color: _textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── TabBar ─────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _surface,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _text,
        unselectedLabelColor: _textMuted,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: _accent, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
        tabs: List.generate(_tabs.length, (i) {
          final count = _countOf(_tabs[i]);
          return Tab(
            child: Row(
              children: [
                Text(_tabLabels[i]),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _statusColor(_tabs[i]).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: _statusColor(_tabs[i]),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  static Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:   return _colorPending;
      case OrderStatus.confirmed: return _colorConfirmed;
      case OrderStatus.preparing: return _colorPreparing;
      case OrderStatus.delivered: return _colorDone;
      default:                    return _accent;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }
}

// ─── Danh sách đơn theo tab ───────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final OrderStatus status;
  final Future<void> Function(Order, OrderStatus) onUpdateStatus;

  const _OrderList({
    required this.orders,
    required this.status,
    required this.onUpdateStatus,
  });

  static const _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emptyIcon(), style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              _emptyMsg(),
              style: const TextStyle(color: _textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: orders.length,
      itemBuilder: (context, i) => _AdminOrderCard(
        order: orders[i],
        onUpdateStatus: onUpdateStatus,
      ),
    );
  }

  String _emptyIcon() {
    switch (status) {
      case OrderStatus.pending:   return '🕐';
      case OrderStatus.confirmed: return '✅';
      case OrderStatus.preparing: return '👨‍🍳';
      case OrderStatus.delivered: return '🎉';
      default:                    return '📋';
    }
  }

  String _emptyMsg() {
    switch (status) {
      case OrderStatus.pending:   return 'Không có đơn chờ xác nhận';
      case OrderStatus.confirmed: return 'Không có đơn đã nhận';
      case OrderStatus.preparing: return 'Không có đơn đang chuẩn bị';
      case OrderStatus.delivered: return 'Chưa có đơn hoàn thành';
      default:                    return 'Không có đơn hàng';
    }
  }
}

// ─── Card đơn hàng (Admin) ────────────────────────────────────
class _AdminOrderCard extends StatefulWidget {
  final Order order;
  final Future<void> Function(Order, OrderStatus) onUpdateStatus;

  const _AdminOrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  static const _surface  = Color(0xFF1A2744);
  static const _border   = Color(0xFF2D3F5C);
  static const _text     = Colors.white;
  static const _textMuted= Color(0xFF94A3B8);

  bool _expanded = false;
  bool _acting   = false;

  // ─── Màu / label / icon theo status ─────────────────────────
  Color get _statusColor {
    switch (widget.order.status) {
      case OrderStatus.pending:   return const Color(0xFFF59E0B);
      case OrderStatus.confirmed: return const Color(0xFF3B82F6);
      case OrderStatus.preparing: return const Color(0xFFA855F7);
      case OrderStatus.delivered: return const Color(0xFF10B981);
      default:                    return const Color(0xFF94A3B8);
    }
  }

  IconData get _statusIcon {
    switch (widget.order.status) {
      case OrderStatus.pending:   return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed: return Icons.check_circle_rounded;
      case OrderStatus.preparing: return Icons.restaurant_rounded;
      case OrderStatus.delivered: return Icons.done_all_rounded;
      default:                    return Icons.info_rounded;
    }
  }

  // Bước tiếp theo
  OrderStatus? get _nextStatus {
    switch (widget.order.status) {
      case OrderStatus.pending:   return OrderStatus.confirmed;
      case OrderStatus.confirmed: return OrderStatus.preparing;
      case OrderStatus.preparing: return null; // dùng slide để complete
      default:                    return null;
    }
  }

  String get _nextLabel {
    switch (widget.order.status) {
      case OrderStatus.pending:   return 'Nhận đơn';
      case OrderStatus.confirmed: return 'Bắt đầu làm';
      default:                    return '';
    }
  }

  IconData get _nextIcon {
    switch (widget.order.status) {
      case OrderStatus.pending:   return Icons.check_rounded;
      case OrderStatus.confirmed: return Icons.restaurant_rounded;
      default:                    return Icons.arrow_forward_rounded;
    }
  }

  Future<void> _advance() async {
    if (_nextStatus == null) return;
    setState(() => _acting = true);
    await widget.onUpdateStatus(widget.order, _nextStatus!);
    if (mounted) setState(() => _acting = false);
  }

  String _formatCurrency(double amount) {
    return amount
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDone = order.status == OrderStatus.delivered;
    final isPreparing = order.status == OrderStatus.preparing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withOpacity(0.35)
              : _statusColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Order ID + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(order.createdAt),
                          style: const TextStyle(
                              color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Amount + expand
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatCurrency(order.totalAmount)} đ',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildDetail(order),
            secondChild: const SizedBox.shrink(),
          ),

          // ── Divider ─────────────────────────────────────────
          if (!isDone)
            Container(height: 1, color: _border.withOpacity(0.6)),

          // ── Action zone ──────────────────────────────────────
          if (!isDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: isPreparing
                  ? _SlideToComplete(
                      onCompleted: () => widget.onUpdateStatus(
                          order, OrderStatus.delivered),
                    )
                  : _buildAdvanceButton(),
            ),
        ],
      ),
    );
  }

  // ── Chi tiết đơn ─────────────────────────────────────────────
  Widget _buildDetail(Order order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF2D3F5C), height: 1),
          const SizedBox(height: 12),

          // Ghi chú / địa chỉ
          if (order.deliveryAddress.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded,
                    color: Color(0xFF94A3B8), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Danh sách món
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.food.name,
                        style: const TextStyle(
                            color: _text, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${_formatCurrency(item.food.price * item.quantity)} đ',
                      style: const TextStyle(
                          color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
              )),

          const Divider(color: Color(0xFF2D3F5C), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng',
                  style: TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(
                '${_formatCurrency(order.totalAmount)} đ',
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Progress steps
          const SizedBox(height: 14),
          _buildProgressSteps(order.status),
        ],
      ),
    );
  }

  // ── Thanh tiến trình ─────────────────────────────────────────
  Widget _buildProgressSteps(OrderStatus current) {
    final steps = [
      (OrderStatus.pending,   'Chờ',    Icons.hourglass_top_rounded),
      (OrderStatus.confirmed, 'Nhận',   Icons.check_circle_rounded),
      (OrderStatus.preparing, 'Làm',    Icons.restaurant_rounded),
      (OrderStatus.delivered, 'Xong',   Icons.done_all_rounded),
    ];

    final currentIdx = steps.indexWhere((s) => s.$1 == current);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          final done = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: done
                  ? const Color(0xFF10B981)
                  : const Color(0xFF2D3F5C),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final (status, label, icon) = steps[stepIdx];
        final isDone = stepIdx <= currentIdx;
        final isCurrent = stepIdx == currentIdx;
        final color = isDone ? const Color(0xFF10B981) : const Color(0xFF2D3F5C);

        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCurrent
                    ? _statusColor.withOpacity(0.2)
                    : isDone
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFF2D3F5C).withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? _statusColor : color,
                  width: 1.5,
                ),
              ),
              child: Icon(icon,
                  size: 15,
                  color: isCurrent
                      ? _statusColor
                      : isDone
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color:
                      isDone ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        );
      }),
    );
  }

  // ── Nút advance (Nhận đơn / Bắt đầu làm) ────────────────────
  Widget _buildAdvanceButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF6366F1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _acting ? null : _advance,
          icon: _acting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(_nextIcon, size: 18),
          label: Text(
            _nextLabel,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

// ─── Slide to Complete ────────────────────────────────────────
class _SlideToComplete extends StatefulWidget {
  final Future<void> Function() onCompleted;

  const _SlideToComplete({required this.onCompleted});

  @override
  State<_SlideToComplete> createState() => _SlideToCompleteState();
}

class _SlideToCompleteState extends State<_SlideToComplete>
    with SingleTickerProviderStateMixin {
  static const _trackColor  = Color(0xFF10B981);
  static const _thumbColor  = Colors.white;
  static const double _thumbSize = 52;
  static const double _trackHeight = 56;
  static const double _padding = 4;

  double _dragX = 0;
  bool _completing = false;
  bool _done = false;

  late final AnimationController _successCtrl;
  late final Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _successAnim = CurvedAnimation(
        parent: _successCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  double _trackWidth(BuildContext context) =>
      MediaQuery.of(context).size.width -
      32 - // card padding
      32;  // section padding

  double get _maxDrag =>
      (_cachedTrackWidth ?? 300) - _thumbSize - _padding * 2;

  double? _cachedTrackWidth;

  double get _progress =>
      _maxDrag > 0 ? (_dragX / _maxDrag).clamp(0.0, 1.0) : 0;

  Future<void> _onComplete() async {
    if (_completing || _done) return;
    setState(() => _completing = true);
    HapticFeedback.heavyImpact();
    await _successCtrl.forward();
    await widget.onCompleted();
    if (mounted) setState(() => _done = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_completing || _done) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (_completing || _done) return;
    if (_progress >= 0.88) {
      setState(() => _dragX = _maxDrag);
      _onComplete();
    } else {
      // Spring back
      setState(() => _dragX = 0);
    }
  }

  Widget _buildDoneState() {
    return Container(
      height: _trackHeight,
      decoration: BoxDecoration(
        color: _trackColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Center(
        child: Icon(Icons.check_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _cachedTrackWidth = _trackWidth(context);

    if (_done) {
      return _buildDoneState();
    }

    return LayoutBuilder(builder: (context, constraints) {
      _cachedTrackWidth = constraints.maxWidth;
      final maxDrag = constraints.maxWidth - _thumbSize - _padding * 2;

      return Container(
        height: _trackHeight,
        decoration: BoxDecoration(
          color: _trackColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _trackColor.withOpacity(0.35), width: 1.2),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Fill bar
            AnimatedContainer(
              duration: Duration.zero,
              width: _padding + _thumbSize + (_dragX),
              height: _trackHeight,
              decoration: BoxDecoration(
                color: _trackColor.withOpacity(0.25 + _progress * 0.2),
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // Label (fades as thumb moves)
            Center(
              child: Opacity(
                opacity: (1 - _progress * 2).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF10B981), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Trượt để hoàn thành',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Thumb
            Positioned(
              left: _padding + _dragX,
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: _successCtrl,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: _completing ? _trackColor : _thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _trackColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _completing ? Icons.hourglass_empty : Icons.arrow_forward_rounded,
                        color: _completing ? Colors.white : _trackColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}