// lib/widgets/coupon_card.dart

import 'package:flutter/material.dart';
import '../models/coupon.dart';

class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback? onApply;
  final bool isAvailable;
  final String buttonText;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onApply,
    this.isAvailable = true,
    this.buttonText = 'Áp dụng',
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpired = DateTime.now().isAfter(coupon.expiryDate);
    final bool isOutOfStock = coupon.usedCount >= coupon.usageLimit;
    final bool isDisabled = !isAvailable || isExpired || isOutOfStock;

    // Shopee-style colors: Percentage is Orange, Fixed amount is Blue
    final Color primaryColor = coupon.discountType == 'percentage' 
        ? const Color(0xFFFF6B00) 
        : const Color(0xFF2196F3);
    
    final Color displayColor = isDisabled ? Colors.grey : primaryColor;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left Strip (Discount value)
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      coupon.discountType == 'percentage'
                          ? '${coupon.discountValue.toInt()}%'
                          : '${(coupon.discountValue / 1000).toInt()}k',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'GIẢM GIÁ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 2. Dashed Divider
              CustomPaint(
                size: const Size(1, double.infinity),
                painter: DashedLinePainter(color: Colors.grey.withOpacity(0.3)),
              ),
  
              // 3. Right Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.code,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDisabled ? Colors.grey : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đơn tối thiểu ${_formatPrice(coupon.minOrderValue)}đ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HSD: ${_formatDate(coupon.expiryDate)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isExpired ? Colors.red : Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${coupon.usageLimit - coupon.usedCount} lượt còn lại',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isOutOfStock ? Colors.red : Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (onApply != null)
                            ElevatedButton(
                              onPressed: isDisabled ? null : onApply,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B00),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                fixedSize: const Size.fromHeight(40),
                              ),
                              child: Text(
                                isExpired ? 'Hết hạn' : (isOutOfStock ? 'Hết lượt' : buttonText),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
