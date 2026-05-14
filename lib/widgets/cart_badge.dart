// lib/widgets/cart_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartBadge extends StatelessWidget {
  final VoidCallback onTap;

  const CartBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().totalQuantity;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 26),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// lib/widgets/quantity_picker.dart (in same file for brevity)

class QuantityPicker extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const QuantityPicker({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(context, Icons.remove, onDecrease,
            enabled: quantity > 0),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        _btn(context, Icons.add, onIncrease),
      ],
    );
  }

  Widget _btn(BuildContext ctx, IconData icon, VoidCallback cb,
      {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? cb : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(ctx).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Theme.of(ctx).primaryColor : Colors.grey[400],
        ),
      ),
    );
  }
}
