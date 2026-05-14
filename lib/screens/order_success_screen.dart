// lib/screens/order_success_screen.dart

import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đặt hàng thành công! 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đơn hàng của bạn đang được xử lý.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Order info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _infoRow('Mã đơn hàng', order.id),
                    const Divider(height: 20),
                    _infoRow('Trạng thái', order.statusLabel),
                    const Divider(height: 20),
                    _infoRow('Tổng tiền', '${_formatPrice(order.totalAmount)}đ'),
                    const Divider(height: 20),
                    _infoRow('Địa chỉ', order.deliveryAddress),
                    const Divider(height: 20),
                    _infoRow('Dự kiến giao', '30 - 45 phút'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
