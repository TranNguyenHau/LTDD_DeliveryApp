import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/firestore_collections.dart';
import '../../models/order.dart';
import '../../providers/review_provider.dart';
import 'admin_food_screen.dart';
import 'admin_coupon_screen.dart';
import 'admin_order_screen.dart';
import 'admin_review_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_account_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  StreamSubscription? _orderSubscription;
  int _pendingOrdersCount = 0;
  
  // GrabFood style banner state
  late AnimationController _bannerController;
  late Animation<Offset> _bannerOffset;
  Order? _newOrder;
  final DateTime _appStartTime = DateTime.now();

  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF3B82F6);
  static const _orange = Color(0xFFFF6B00);
  static const _textMuted = Color(0xFF94A3B8);

  final List<Widget> _screens = const [
    AdminFoodScreen(),
    AdminCouponScreen(),
    AdminOrderScreen(),
    AdminReviewScreen(),
    AdminStatsScreen(),
    AdminAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup Banner Animation
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerOffset = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutBack,
    ));

    // Listen for new pending orders
    _orderSubscription = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .where('status', isEqualTo: OrderStatus.pending.name)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() => _pendingOrdersCount = snapshot.docs.length);
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final order = Order.fromMap(change.doc.data() as Map<String, dynamic>);
          // Only show banner for orders created after admin opened the shell
          if (order.createdAt.isAfter(_appStartTime)) {
            _showNewOrderBanner(order);
          }
        }
      }
    });
  }

  void _showNewOrderBanner(Order order) {
    if (!mounted) return;
    setState(() => _newOrder = order);
    _bannerController.forward();
    
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _bannerController.reverse();
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildTabIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _surface, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    
    final pendingOrdersCount = _pendingOrdersCount;
    final unrepliedReviewsCount = reviewProvider.allReviews.where((r) => r.adminReply == null || r.adminReply!.isEmpty).length;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          
          // GrabFood style Banner
          SlideTransition(
            position: _bannerOffset,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: _newOrder == null ? const SizedBox() : Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ĐƠN HÀNG MỚI! 🔔',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '#${_newOrder!.id.substring(0, 8).toUpperCase()} - ${NumberFormat.decimalPattern().format(_newOrder!.totalAmount)}đ',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _bannerController.reverse();
                          setState(() => _selectedIndex = 2); // Go to Orders tab
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('XEM', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: _surface,
        selectedItemColor: _accent,
        unselectedItemColor: _textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Món ăn',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_rounded),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.local_shipping_rounded, pendingOrdersCount),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.star_rounded, unrepliedReviewsCount),
            label: 'Đánh giá',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
