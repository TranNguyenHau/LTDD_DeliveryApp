import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../main_shell.dart';
import '../login.dart';
import '../../providers/food_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/coupon_provider.dart';

class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key});

  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF3B82F6);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);
  static const _danger = Color(0xFFEF4444);

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text("Đăng xuất?", style: TextStyle(color: _text)),
        content: const Text("Bạn có chắc muốn đăng xuất khỏi tài khoản admin?", style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear all providers
      context.read<FoodProvider>().clear();
      context.read<CartProvider>().clear();
      context.read<OrderProvider>().clear();
      context.read<ProfileProvider>().clear();
      context.read<ReviewProvider>().clear();
      context.read<CouponProvider>().clear();

      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text("Tài khoản Admin", style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: _accent,
              child: Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? "Admin",
              style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Quản trị viên hệ thống",
              style: TextStyle(color: _textMuted, fontSize: 14),
            ),
            const SizedBox(height: 40),
            
            _buildMenuButton(
              icon: Icons.storefront_rounded,
              label: "Về giao diện Cửa hàng",
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              icon: Icons.logout_rounded,
              label: "Đăng xuất",
              color: _danger,
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? _accent),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color ?? _text, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: _textMuted.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
