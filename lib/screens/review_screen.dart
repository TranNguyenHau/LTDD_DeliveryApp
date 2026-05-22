// lib/screens/review_screen.dart
// Viết đánh giá + danh sách đánh giá của món ăn (theo đơn hàng)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/review.dart';
import '../providers/profile_provider.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends StatefulWidget {
  final FoodItem food;
  final String orderId;

  const ReviewScreen({
    super.key,
    required this.food,
    required this.orderId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviewsForFood(widget.food.id);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnack('Vui lòng đăng nhập', isError: true);
      return;
    }

    final profile = context.read<ProfileProvider>().profile;
    final userName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : FirebaseAuth.instance.currentUser?.email ?? 'Khách';

    final error = await context.read<ReviewProvider>().submitReview(
          userId: uid,
          userName: userName,
          orderId: widget.orderId,
          foodId: widget.food.id,
          foodName: widget.food.name,
          rating: _selectedRating,
          comment: _commentCtrl.text,
        );

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack('Cảm ơn bạn đã đánh giá!');
      _commentCtrl.clear();
      setState(() => _selectedRating = 5);
      Navigator.pop(context, true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('Đánh giá: ${widget.food.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RatingSummary(
              rating: reviewProvider.averageRating,
              count: reviewProvider.reviewCount,
            ),
            const SizedBox(height: 20),

            // Form đánh giá — chỉ khi chưa đánh giá món này trong đơn này
            if (uid != null)
              FutureBuilder<bool>(
                future: reviewProvider.hasUserReviewedFoodInOrder(
                  uid,
                  widget.food.id,
                  widget.orderId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final hasReviewed = snapshot.data ?? false;

                  if (hasReviewed) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF22C55E), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn đã đánh giá món này trong đơn hàng này.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đánh giá của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StarPicker(
                        rating: _selectedRating,
                        onChanged: (v) => setState(() => _selectedRating = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Viết nhận xét của bạn...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              reviewProvider.isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: reviewProvider.isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Gửi đánh giá',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

            Text(
              'Tất cả đánh giá (${reviewProvider.reviewCount})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviewProvider.reviews.isEmpty)
              Text(
                'Chưa có đánh giá nào',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...reviewProvider.reviews.map(
                (r) => _ReviewTile(review: r),
              ),
          ],
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double rating;
  final int count;

  const _RatingSummary({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    final display = rating > 0 ? rating.toStringAsFixed(1) : '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                display,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$count đánh giá',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 36,
          ),
        );
      }),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (review.comment.isNotEmpty)
            Text(review.comment, style: TextStyle(color: Colors.grey[800])),
          const SizedBox(height: 4),
          Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
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
                          size: 14, color: Color(0xFFFF6B00)),
                      SizedBox(width: 6),
                      Text(
                        'Phản hồi từ nhà hàng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.adminReply!,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
