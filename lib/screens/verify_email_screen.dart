// lib/screens/verify_email_screen.dart
// Xác thực email sau đăng ký hoặc khi đăng nhập chưa verify

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/order_provider.dart';
import '../providers/profile_provider.dart';
import 'login.dart';
import 'main_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  /// Đăng ký: quay lại RegisterScreen bước 2
  final VoidCallback? onVerified;

  /// Đăng nhập: sau verify → bind providers → MainShell
  final Account? loginAccount;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.onVerified,
    this.loginAccount,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _orange = Color(0xFFFF6B00);
  static const _orangeLight = Color(0xFFFF9500);

  bool _isChecking = false;
  bool _isSending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        setState(() => _resendCooldown = 0);
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isSending) return;
    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      _showSnack('Đã gửi lại email xác thực!');
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gửi lại email thất bại, thử lại sau', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final verified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (!mounted) return;

      if (!verified) {
        _showSnack(
          'Email chưa được xác thực, vui lòng kiểm tra hộp thư',
          isError: true,
        );
        return;
      }

      // Luồng đăng nhập: bind providers → MainShell
      if (widget.loginAccount != null) {
        final account = widget.loginAccount!;
        await Future.wait([
          context.read<ProfileProvider>().bindUser(
                account.id,
                email: account.email,
                fullName: account.username,
              ),
          context.read<OrderProvider>().bindUser(account.id),
        ]);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
        return;
      }

      // Luồng đăng ký: pop → callback → RegisterScreen bước 2
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
      widget.onVerified?.call();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không thể kiểm tra trạng thái: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Xác thực email',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_orange, _orangeLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác thực email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chúng tôi đã gửi link xác thực đến\n${widget.email}\nVui lòng kiểm tra hộp thư và nhấn link xác thực.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tôi đã xác thực ✓',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    (_resendCooldown > 0 || _isSending) ? null : _resendEmail,
                child: Text(
                  _resendCooldown > 0
                      ? 'Gửi lại email (${_resendCooldown}s)'
                      : 'Gửi lại email',
                  style: TextStyle(
                    color: _resendCooldown > 0 ? Colors.grey : _orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
