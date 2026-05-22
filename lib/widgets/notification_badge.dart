// lib/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 28),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
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
