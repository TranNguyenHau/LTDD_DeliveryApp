// lib/screens/food_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_badge.dart';
import 'cart_screen.dart';

class FoodDetailScreen extends StatelessWidget {
  final FoodItem food;

  const FoodDetailScreen({super.key, required this.food});

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(food.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: CartBadge(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen()))),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                food.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, size: 60),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  if (food.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: food.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 12),

                  // Name & price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${_formatPrice(food.price)}đ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      _statChip(Icons.star, Colors.amber,
                          '${food.rating} (${food.reviewCount})'),
                      const SizedBox(width: 12),
                      _statChip(Icons.timer_outlined, Colors.blue,
                          '${food.prepTimeMinutes} phút'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Mô tả',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    food.description,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.6),
                  ),
                  const SizedBox(height: 30),

                  // Quantity + Add to cart
                  Row(
                    children: [
                      // Qty
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: qty > 0
                                  ? () => context
                                      .read<CartProvider>()
                                      .removeItem(food.id)
                                  : null,
                              icon: const Icon(Icons.remove),
                              iconSize: 20,
                            ),
                            Text(
                              qty.toString(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              onPressed: () =>
                                  context.read<CartProvider>().addItem(food),
                              icon: const Icon(Icons.add),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<CartProvider>().addItem(food);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm ${food.name} vào giỏ!'),
                                duration: const Duration(seconds: 1),
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Thêm vào giỏ hàng',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }
}
