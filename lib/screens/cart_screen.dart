// lib/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.totalQuantity})'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xóa tất cả?'),
                  content: const Text('Bạn có chắc muốn xóa toàn bộ giỏ hàng?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy')),
                    TextButton(
                        onPressed: () {
                          context.read<CartProvider>().clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Xóa',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('Giỏ hàng trống',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Hãy thêm món ăn yêu thích!',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Khám phá món ăn'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                item.food.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.restaurant),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.food.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatPrice(item.food.price)}đ / phần',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Controls
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatPrice(item.totalPrice)}đ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _qtyBtn(
                                        context,
                                        Icons.remove,
                                        () => context
                                            .read<CartProvider>()
                                            .removeItem(item.food.id)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(item.quantity.toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    _qtyBtn(
                                        context,
                                        Icons.add,
                                        () => context
                                            .read<CartProvider>()
                                            .addItem(item.food)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Bottom summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tạm tính (${cart.totalQuantity} món)',
                              style: TextStyle(color: Colors.grey[600])),
                          Text('${_formatPrice(cart.totalAmount)}đ'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí giao hàng',
                              style: TextStyle(color: Colors.grey[600])),
                          const Text('15.000đ'),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(
                            '${_formatPrice(cart.totalAmount + 15000)}đ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen())),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Đặt hàng ngay',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyBtn(BuildContext ctx, IconData icon, VoidCallback cb) {
    return GestureDetector(
      onTap: cb,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Theme.of(ctx).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Theme.of(ctx).primaryColor),
      ),
    );
  }
}
