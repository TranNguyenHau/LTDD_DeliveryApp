import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/firestore_collections.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF3B82F6);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);
  static const _danger = Color(0xFFEF4444);

  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus nextStatus) async {
    setState(() => _isUpdating = true);
    try {
      final error = await context.read<OrderProvider>().updateOrderStatus(
            widget.orderId,
            nextStatus,
          );
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi cập nhật: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget? _buildActionButton(OrderStatus currentStatus) {
    String label = '';
    OrderStatus? nextStatus;
    Color color = _accent;

    switch (currentStatus) {
      case OrderStatus.pending:
        label = 'Xác nhận đơn hàng';
        nextStatus = OrderStatus.confirmed;
        break;
      case OrderStatus.confirmed:
        label = 'Bắt đầu chuẩn bị';
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        label = 'Giao hàng';
        nextStatus = OrderStatus.delivering;
        break;
      case OrderStatus.delivering:
        label = 'Hoàn thành đơn hàng';
        nextStatus = OrderStatus.completed;
        color = Colors.green;
        break;
      default:
        return null;
    }

    return ElevatedButton(
      onPressed: _isUpdating ? null : () => _updateStatus(nextStatus!),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text("Chi tiết đơn hàng",
            style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirestoreCollections.orders)
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) {
            return const Center(
                child: Text("Đơn hàng không tồn tại", style: TextStyle(color: _textMuted)));
          }

          final order = Order.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          final actionBtn = _buildActionButton(order.status);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info
                      _buildSection(
                        child: Column(
                          children: [
                            _buildInfoRow("Mã đơn hàng", "#${order.id.toUpperCase()}", isBold: true),
                            const Divider(color: _border, height: 24),
                            _buildInfoRow("Thời gian",
                                DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
                            const SizedBox(height: 8),
                            _buildInfoRow("Trạng thái", order.statusLabel,
                                valueColor: _getStatusColor(order.status)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Delivery info
                      const Text("GIAO ĐẾN",
                          style: TextStyle(
                              color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildSection(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: _accent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(order.deliveryAddress,
                                    style: const TextStyle(color: _text, height: 1.4))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Items list
                      const Text("MÓN ĂN",
                          style: TextStyle(
                              color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildSection(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: order.items.map((item) => _buildItemTile(item)).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment summary
                      const Text("THANH TOÁN",
                          style: TextStyle(
                              color: _textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildSection(
                        child: Column(
                          children: [
                            _buildInfoRow("Tạm tính",
                                "${NumberFormat.decimalPattern().format(order.totalAmount + order.discountAmount)}đ"),
                            const SizedBox(height: 8),
                            if (order.discountAmount > 0) ...[
                              _buildInfoRow(
                                  "Giảm giá (${order.couponCode})",
                                  "-${NumberFormat.decimalPattern().format(order.discountAmount)}đ",
                                  valueColor: Colors.red),
                              const SizedBox(height: 8),
                            ],
                            const Divider(color: _border, height: 20),
                            _buildInfoRow(
                              "Tổng cộng",
                              "${NumberFormat.decimalPattern().format(order.totalAmount)}đ",
                              isBold: true,
                              fontSize: 18,
                              valueColor: const Color(0xFF34D399),
                            ),
                          ],
                        ),
                      ),

                      if (order.status == OrderStatus.cancelled && order.cancelReason != null) ...[
                        const SizedBox(height: 24),
                        Text("LÝ DO HỦY",
                            style: TextStyle(
                                color: _danger, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildSection(
                          child: Text(order.cancelReason!, style: const TextStyle(color: _danger)),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              if (actionBtn != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    border: const Border(top: BorderSide(color: _border)),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: actionBtn,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, double fontSize = 14, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _text,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(dynamic item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: _textMuted),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text("${item.quantity}x",
                style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.food.name,
                    style: const TextStyle(color: _text, fontWeight: FontWeight.w600)),
                if (item.food.price > 0)
                  Text("${NumberFormat.decimalPattern().format(item.food.price)}đ",
                      style: const TextStyle(color: _textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "${NumberFormat.decimalPattern().format(item.food.price * item.quantity)}đ",
            style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.delivering:
        return Colors.cyan;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
