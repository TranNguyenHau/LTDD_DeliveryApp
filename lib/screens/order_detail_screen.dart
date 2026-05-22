// lib/screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final List<String> _cancelReasons = [
    "Đặt nhầm món",
    "Muốn thay đổi địa chỉ",
    "Tìm được chỗ khác",
    "Lý do khác"
  ];
  String? _selectedReason;

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  void _showCancelDialog(BuildContext context, OrderProvider provider) {
    _selectedReason = _cancelReasons[0];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Xác nhận hủy đơn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vui lòng chọn lý do hủy:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _selectedReason,
                isExpanded: true,
                items: _cancelReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setDialogState(() => _selectedReason = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final success = await provider.cancelOrder(widget.orderId, _selectedReason!);
                if (ctx.mounted) Navigator.pop(ctx);
                
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đơn hàng đã được hủy thành công')),
                    );
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) Navigator.pop(context);
                  }
                }
              },
              child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<Order>(
        stream: orderProvider.getOrderStream(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data!;
          final subtotal = order.items.fold(0.0, (sum, item) => sum + item.totalPrice);
          const deliveryFee = 15000.0;
          final orderIdDisplay = order.id.length > 16 
              ? '${order.id.substring(0, 16)}...' 
              : order.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                _card(children: [
                  _row('Mã đơn hàng', orderIdDisplay),
                  const Divider(height: 24),
                  _row('Thời gian đặt', DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
                  const Divider(height: 24),
                  _row('Địa chỉ giao', order.deliveryAddress),
                ]),
                const SizedBox(height: 16),

                // Status Stepper
                const Text('Trạng thái đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _card(children: [
                   _buildStepper(order.status),
                ]),
                const SizedBox(height: 16),

                // Items list
                const Text('Món đã đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _card(children: [
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.food.name} x${item.quantity}', style: const TextStyle(fontSize: 14)),
                        Text('${_formatPrice(item.totalPrice)}đ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  const Divider(height: 24),
                  _summaryRow('Tạm tính', '${_formatPrice(subtotal)}đ'),
                  if (order.discountAmount > 0)
                    _summaryRow('Giảm giá', '-${_formatPrice(order.discountAmount)}đ', valueColor: Colors.red),
                  _summaryRow('Phí giao hàng', '${_formatPrice(deliveryFee)}đ'),
                  const Divider(height: 24),
                  _summaryRow('Tổng cộng', '${_formatPrice(order.totalAmount)}đ', isTotal: true),
                ]),
                const SizedBox(height: 24),

                // Cancel button
                if (order.status == OrderStatus.pending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showCancelDialog(context, orderProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                
                if (order.status == OrderStatus.cancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('Lý do hủy: ${order.cancelReason ?? "N/A"}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepper(OrderStatus currentStatus) {
    if (currentStatus == OrderStatus.cancelled) {
       return const Row(
         children: [
           Icon(Icons.cancel, color: Colors.red),
           SizedBox(width: 8),
           Text('Đơn hàng này đã bị hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
         ],
       );
    }

    final steps = [
      {'label': 'Chờ xác nhận', 'status': OrderStatus.pending},
      {'label': 'Đã xác nhận', 'status': OrderStatus.confirmed},
      {'label': 'Đang chuẩn bị', 'status': OrderStatus.preparing},
      {'label': 'Đang giao', 'status': OrderStatus.delivering},
      {'label': 'Hoàn thành', 'status': OrderStatus.completed},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);

    return Column(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index < currentIndex;
        bool isActive = index == currentIndex;
        Color color = isCompleted ? Colors.green : (isActive ? Colors.orange : Colors.grey);

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                ),
                if (index != steps.length - 1)
                  Container(width: 2, height: 30, color: index < currentIndex ? Colors.green : Colors.grey[300]),
              ],
            ),
            const SizedBox(width: 12),
            Text(steps[index]['label'] as String, style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: valueColor ?? (isTotal ? Colors.orange : Colors.black))),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 16),
        Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
      ],
    );
  }
}
