// lib/screens/notification_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import 'order_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await context.read<NotificationProvider>().loadNotifications(uid);
      }
      if (mounted) setState(() => _initialized = true);
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'hôm qua';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  void _handleNotificationTap(AppNotification notif) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      context.read<NotificationProvider>().markAsRead(uid, notif.id);
    }

    if (notif.type == 'order_status' && notif.orderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: notif.orderId!),
        ),
      );
    }
    // Note: ReviewScreen requires FoodItem which we don't have here.
    // For now, per requirement, we skip navigation for admin_reply.
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (uid != null && notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => provider.markAllAsRead(uid),
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(color: Color(0xFFFF6B00), fontSize: 13),
              ),
            ),
        ],
      ),
      body: !_initialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (ctx, i) {
                    return _NotificationItem(
                      notification: notifications[i],
                      timeAgo: _getTimeAgo(notifications[i].createdAt),
                      onTap: () => _handleNotificationTap(notifications[i]),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.grey[50],
          border: isUnread
              ? const Border(
                  left: BorderSide(color: Color(0xFFFF6B00), width: 4),
                  bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
                )
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEADC),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  notification.type == 'order_status' ? '🛵' : '💬',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
