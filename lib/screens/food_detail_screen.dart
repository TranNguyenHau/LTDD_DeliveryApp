// lib/screens/food_detail_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/cart_badge.dart';
import 'cart_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviewsForFood(widget.food.id);
    });
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  // ─── Hiển thị ảnh theo loại: base64 / asset / network ─────
  Widget _buildImage(String imageUrl) {
    Widget fallback = Container(
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, size: 60, color: Colors.grey),
    );

    if (imageUrl.isEmpty) return fallback;

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final qty = cart.quantityOf(widget.food.id);

    final avgRating = reviewProvider.reviewCount > 0
        ? reviewProvider.averageRating.toStringAsFixed(1)
        : widget.food.rating.toStringAsFixed(1);
    final reviewCount = reviewProvider.reviewCount > 0
        ? reviewProvider.reviewCount
        : widget.food.reviewCount;

    final previewReviews = reviewProvider.reviews.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
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
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen()))),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImage(widget.food.imageUrl),
            ),
          ),
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
                  if (widget.food.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: widget.food.tags
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.food.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${_formatPrice(widget.food.price)}đ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statChip(Icons.star, Colors.amber,
                          '$avgRating ($reviewCount đánh giá)'),
                      const SizedBox(width: 12),
                      _statChip(Icons.timer_outlined, Colors.blue,
                          '${widget.food.prepTimeMinutes} phút'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mô tả',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.food.description,
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // Đánh giá
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đánh giá',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đánh giá từng món trong tab Lịch sử đơn hàng',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (reviewProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (previewReviews.isEmpty)
                    Text(
                      'Chưa có đánh giá',
                      style:
                      TextStyle(color: Colors.grey[600], fontSize: 13),
                    )
                  else ...[
                      ...previewReviews.map(
                            (r) => _CompactReviewTile(review: r),
                      ),
                      if (reviewProvider.reviewCount > 3)
                        Text(
                          'Xem thêm trong danh sách bên dưới khi cuộn',
                          style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  const SizedBox(height: 24),

                  Row(
                    children: [
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
                                  .removeItem(widget.food.id)
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
                              onPressed: () => context
                                  .read<CartProvider>()
                                  .addItem(widget.food),
                              icon: const Icon(Icons.add),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<CartProvider>().addItem(widget.food);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Đã thêm ${widget.food.name} vào giỏ!'),
                                duration: const Duration(seconds: 1),
                                backgroundColor:
                                Theme.of(context).primaryColor,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }
}

class _CompactReviewTile extends StatelessWidget {
  final Review review;

  const _CompactReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 12,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            DateFormat('dd/MM/yyyy').format(review.createdAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
          if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 12, color: Color(0xFFFF6B00)),
                      SizedBox(width: 4),
                      Text("Phản hồi từ nhà hàng",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF6B00))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review.adminReply!,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}