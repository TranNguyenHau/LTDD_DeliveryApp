// lib/widgets/food_card.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';

class FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;

  const FoodCard({super.key, required this.food, this.onTap});

  // ─── Hiển thị ảnh theo loại: base64 / asset / network ─────
  Widget _buildImage(String imageUrl) {
    // Placeholder dùng chung khi không có ảnh hoặc lỗi
    Widget placeholder({bool loading = false}) => Container(
      color: Colors.grey[100],
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Icon(Icons.restaurant, size: 40, color: Colors.grey),
      ),
    );

    if (imageUrl.isEmpty) return placeholder();

    // Ảnh base64 (lưu trong Firestore)
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder(),
        );
      } catch (_) {
        return placeholder();
      }
    }

    // Ảnh asset local
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }

    // Ảnh network (URL http/https) — dùng cache
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder(loading: true),
      errorWidget: (_, __, ___) => placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.containsFood(food.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(food.imageUrl),
                    if (food.isPopular)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Phổ biến',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          food.rating.toString(),
                          style:
                          TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        Text(
                          '${food.prepTimeMinutes} phút',
                          style:
                          TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatPrice(food.price)}đ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.read<CartProvider>().addItem(food),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: inCart
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: inCart
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
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
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}