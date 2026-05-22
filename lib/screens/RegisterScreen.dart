// lib/screens/RegisterScreen.dart
// 2-step registration: (1) Username + Password → (2) Phone number
// Inspired by ShopeeFood / GrabFood onboarding flow

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:food_app/services/auth_service.dart';
import 'package:food_app/providers/profile_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ─── Theme ───────────────────────────────────────────────
  static const _orange = Color(0xFFFF6B00);
  static const _orangeLight = Color(0xFFFF9500);
  static const _bg = Color(0xFFFFF8F3);
  static const _surface = Colors.white;
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF9E9E9E);
  static const _border = Color(0xFFE0E0E0);
  static const _borderFocus = Color(0xFFFF6B00);

  // ─── Step 1 ──────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  // ─── Step 2 ──────────────────────────────────────────────
  final _step2Key = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  // ─── State ───────────────────────────────────────────────
  int _currentStep = 0; // 0 = account info, 1 = phone number
  bool _isLoading = false;
  String? _registeredUserId; // UID sau khi đăng ký xong bước 1

  late AnimationController _pageCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut),
    );
    _pageCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Đăng ký tài khoản ───────────────────────────
  Future<void> _registerAccount() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final account = await AuthService().register(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      _registeredUserId = account.id;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
      _progressCtrl.forward();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = (e.code == 'username-already-in-use' ||
              e.code == 'email-already-in-use')
          ? 'Username đã tồn tại, vui lòng chọn tên khác'
          : (e.message ?? 'Đăng ký thất bại');
      _showSnack(msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Lỗi: $e', isError: true);
    }
  }

  // ─── Step 2: Lưu số điện thoại ───────────────────────────
  Future<void> _savePhone() async {
    if (!_step2Key.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Lưu phone vào Firestore thông qua ProfileProvider
      final profileProvider = context.read<ProfileProvider>();

      // Bind user nếu chưa bind
      if (_registeredUserId != null) {
        await profileProvider.bindUser(_registeredUserId!);
        await profileProvider.updateProfile(
          fullName: _usernameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: '',
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSnack('Đăng ký thành công! Hãy đăng nhập.', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Lỗi lưu thông tin: $e', isError: true);
    }
  }

  // ─── Skip số điện thoại ──────────────────────────────────
  Future<void> _skipPhone() async {
    _showSnack('Bạn có thể cập nhật số điện thoại sau trong phần Hồ sơ',
        isError: false);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            _buildHeader(),

            // ── Progress indicator ───────────────────────────
            _buildProgressBar(),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _currentStep == 0
                    ? _buildStep1(key: const ValueKey('step1'))
                    : _buildStep2(key: const ValueKey('step2')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep == 1) {
                setState(() => _currentStep = 0);
                _progressCtrl.reverse();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: _textDark),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Text(
                _currentStep == 0
                    ? 'Bước 1/2 — Thông tin đăng nhập'
                    : 'Bước 2/2 — Số điện thoại',
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Progress bar ─────────────────────────────────────────
  Widget _buildProgressBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (_, __) {
          final progress = _currentStep == 0 ? 0.5 : _progressAnim.value;
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_orange),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _stepDot(1, _currentStep >= 0, 'Tài khoản'),
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: _currentStep >= 1
                          ? _orange
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  _stepDot(2, _currentStep >= 1, 'Số điện thoại'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepDot(int number, bool active, String label) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _orange : const Color(0xFFE0E0E0),
          ),
          child: Center(
            child: active && number < (_currentStep + 1)
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : _textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? _orange : _textMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ─── Step 1: Tài khoản ────────────────────────────────────
  Widget _buildStep1({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Icon + title
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_orange, _orangeLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.person_outline, size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Tạo tài khoản mới',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Nhập thông tin để bắt đầu đặt món',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
            ),

            const SizedBox(height: 28),

            // Username
            _fieldLabel('Tên đăng nhập'),
            _inputField(
              controller: _usernameCtrl,
              hint: 'Ít nhất 3 ký tự',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập username';
                if (v.trim().length < 3) return 'Username ít nhất 3 ký tự';
                if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(v.trim())) {
                  return 'Chỉ dùng chữ cái, số và dấu gạch dưới';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _fieldLabel('Mật khẩu'),
            _inputField(
              controller: _passwordCtrl,
              hint: 'Ít nhất 6 ký tự',
              icon: Icons.lock_outline,
              obscure: _hidePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _fieldLabel('Xác nhận mật khẩu'),
            _inputField(
              controller: _confirmCtrl,
              hint: 'Nhập lại mật khẩu',
              icon: Icons.lock_outline,
              obscure: _hideConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Button
            _primaryButton(
              label: 'Tiếp tục',
              icon: Icons.arrow_forward_rounded,
              onTap: _registerAccount,
            ),

            const SizedBox(height: 20),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản?',
                    style: TextStyle(color: _textMuted, fontSize: 14)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Số điện thoại ────────────────────────────────
  Widget _buildStep2({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Icon + title
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.phone_outlined,
                    size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Số điện thoại của bạn',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Dùng để nhận thông báo đơn hàng\nvà liên hệ khi giao hàng',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _textMuted, height: 1.5),
              ),
            ),

            const SizedBox(height: 32),

            // Phone field with +84 prefix
            _fieldLabel('Số điện thoại'),
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Prefix
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 18),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _border),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Vietnam flag emoji
                        const Text('🇻🇳', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        const Text('+84',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                              fontSize: 15,
                            )),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16, color: _textMuted),
                      ],
                    ),
                  ),
                  // Input
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textDark),
                      decoration: const InputDecoration(
                        hintText: '09x xxx xxxx',
                        hintStyle:
                            TextStyle(color: _textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        if (!RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$')
                            .hasMatch(v.trim())) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFFF8F00)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Số điện thoại sẽ được dùng để giao hàng và hỗ trợ đơn hàng',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF795548),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Confirm button
            _primaryButton(
              label: 'Hoàn tất đăng ký',
              icon: Icons.check_circle_outline_rounded,
              onTap: _savePhone,
            ),

            const SizedBox(height: 14),

            // Skip button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : _skipPhone,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: _border),
                  ),
                ),
                child: const Text(
                  'Bỏ qua, thêm sau',
                  style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
            fontSize: 15, color: _textDark, fontWeight: FontWeight.w500),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: _textMuted, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _borderFocus, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          disabledBackgroundColor: _orange.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }
}