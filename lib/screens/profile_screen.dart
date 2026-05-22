// lib/screens/profile_screen.dart
// Hồ sơ người dùng — view mode mặc định, edit mode khi bấm nút
// Style tham khảo GrabFood / ShopeeFood

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/cart_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/order_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/validators.dart';
import 'coupon_wallet_screen.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ─── Theme ───────────────────────────────────────────────
  static const _orange = Color(0xFFFF6B00);
  static const _bg = Color(0xFFF5F5F5);
  static const _surface = Colors.white;
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF9E9E9E);
  static const _border = Color(0xFFEEEEEE);
  static const _red = Color(0xFFEF4444);

  // ─── State ───────────────────────────────────────────────
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _lastSyncedAt;

  late AnimationController _editAnimCtrl;
  late Animation<double> _editAnim;

  @override
  void initState() {
    super.initState();
    _editAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _editAnim = CurvedAnimation(parent: _editAnimCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _editAnimCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(UserProfile profile) {
    if (_lastSyncedAt == profile.updatedAt) return;
    _fullNameCtrl.text = profile.fullName;
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
    _addressCtrl.text = profile.address;
    _lastSyncedAt = profile.updatedAt;
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
    if (_isEditing) {
      _editAnimCtrl.forward();
    } else {
      _editAnimCtrl.reverse();
      // Reset về data hiện tại nếu cancel
      _lastSyncedAt = null;
      final profile = context.read<ProfileProvider>().profile;
      if (profile != null) _syncControllers(profile);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final error =
        await context.read<ProfileProvider>().uploadAvatar(File(picked.path));
    if (!mounted) return;
    _showSnack(
      error ?? 'Cập nhật ảnh đại diện thành công!',
      isError: error != null,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProfileProvider>();
    final error = await provider.updateProfile(
      fullName: _fullNameCtrl.text,
      phone: _phoneCtrl.text,
      address: _addressCtrl.text,
    );
    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack('Cập nhật hồ sơ thành công!');
      setState(() => _isEditing = false);
      _editAnimCtrl.reverse();
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoutBottomSheet(),
    );
    if (confirmed == true && mounted) {
      // 1. Clear all provider state first
      context.read<CartProvider>().clear();
      context.read<CouponProvider>().clear();
      await context.read<OrderProvider>().clear();
      await context.read<ProfileProvider>().clear();
      
      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // 3. Navigate to login, remove ALL routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
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
            isError ? _red : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    if (profile != null && !_isEditing) {
      _syncControllers(profile);
    }

    return Scaffold(
      backgroundColor: _bg,
      // ── AppBar ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        actions: [
          if (profile != null)
            TextButton(
              onPressed: _toggleEdit,
              child: Text(
                _isEditing ? 'Hủy' : 'Chỉnh sửa',
                style: TextStyle(
                  color: _isEditing ? _textMuted : _orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      // ── Body ─────────────────────────────────────────────
      body: profileProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _orange),
            )
          : profile == null
              ? Center(
                  child: Text(
                    profileProvider.errorMessage ?? 'Không tải được hồ sơ',
                    style: const TextStyle(color: _textMuted),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Avatar section ───────────────────
                      _buildAvatarSection(profile, profileProvider),

                      // ── Info / Form ──────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isEditing
                            ? _buildEditForm(profile, profileProvider)
                            : _buildViewMode(profile),
                      ),

                      // ── Logout section ───────────────────
                      if (!_isEditing) _buildLogoutSection(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  // ─── Avatar section ───────────────────────────────────────
  Widget _buildAvatarSection(UserProfile profile, ProfileProvider provider) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFFF0F0F0),
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 52, color: Color(0xFFBDBDBD))
                      : null,
                ),
              ),
              // Edit avatar button
              if (_isEditing)
                GestureDetector(
                  onTap: provider.isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: provider.isUploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName.isNotEmpty ? profile.fullName : 'Chưa cập nhật',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ─── View mode ────────────────────────────────────────────
  Widget _buildViewMode(UserProfile profile) {
    return Container(
      key: const ValueKey('view'),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          _infoCard(children: [
            _infoRow(
              icon: Icons.person_outline,
              label: 'Họ và tên',
              value: profile.fullName.isNotEmpty
                  ? profile.fullName
                  : 'Chưa cập nhật',
              isEmpty: profile.fullName.isEmpty,
            ),
            _divider(),
            _infoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.email,
            ),
            _divider(),
            _infoRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: profile.phone.isNotEmpty ? profile.phone : 'Chưa cập nhật',
              isEmpty: profile.phone.isEmpty,
            ),
          ]),
          const SizedBox(height: 12),
          _infoCard(children: [
            _infoRow(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ giao hàng',
              value: profile.address.isNotEmpty
                  ? profile.address
                  : 'Chưa có địa chỉ — Thêm để đặt hàng nhanh hơn',
              isEmpty: profile.address.isEmpty,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isEmpty = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _orange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: _textMuted)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEmpty ? _textMuted : _textDark,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFDDDDDD)),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 50, endIndent: 16, color: _border);
  }

  // ─── Edit mode ────────────────────────────────────────────
  Widget _buildEditForm(UserProfile profile, ProfileProvider provider) {
    return Container(
      key: const ValueKey('edit'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.edit_outlined, size: 18, color: _orange),
              const SizedBox(width: 8),
              const Text(
                'Chỉnh sửa thông tin',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark),
              ),
            ]),
            const SizedBox(height: 20),

            _editField(
              controller: _fullNameCtrl,
              label: 'Họ và tên',
              icon: Icons.person_outline,
              validator: AppValidators.fullName,
            ),
            const SizedBox(height: 14),

            _editField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              readOnly: true,
              helperText: 'Không thể thay đổi email đăng nhập',
            ),
            const SizedBox(height: 14),

            _editField(
              controller: _phoneCtrl,
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: AppValidators.phone,
            ),
            const SizedBox(height: 14),

            _editField(
              controller: _addressCtrl,
              label: 'Địa chỉ giao hàng',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: AppValidators.address,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  disabledBackgroundColor: _orange.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: provider.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? _textMuted : _textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập $label',
            hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: _textMuted),
            helperText: helperText,
            helperStyle: const TextStyle(fontSize: 11, color: _textMuted),
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF9F9F9)
                : const Color(0xFFFFF8F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ─── Logout section ───────────────────────────────────────
  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          // App version info (optional cosmetic)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _menuRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Kho voucher',
                  iconColor: _orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CouponWalletScreen()),
                  ),
                ),
                _divider(),
                _menuRow(
                  icon: Icons.notifications_outlined,
                  label: 'Thông báo',
                  iconColor: const Color(0xFF5C6BC0),
                  onTap: () {},
                ),
                _divider(),
                _menuRow(
                  icon: Icons.shield_outlined,
                  label: 'Bảo mật & Quyền riêng tư',
                  iconColor: const Color(0xFF26A69A),
                  onTap: () {},
                ),
                _divider(),
                _menuRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Trợ giúp & Hỗ trợ',
                  iconColor: const Color(0xFFFF8F00),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Logout button
          GestureDetector(
            onTap: _confirmLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.logout_rounded, size: 18, color: _red),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _red,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFFDDDDDD)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: Color(0xFFDDDDDD)),
          ],
        ),
      ),
    );
  }
}

// ─── Logout bottom sheet ──────────────────────────────────
class _LogoutBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded,
                size: 30, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),

          const Text(
            'Đăng xuất?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn sẽ cần đăng nhập lại để tiếp tục\nsử dụng ứng dụng.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              // Cancel
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Confirm logout
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Khởi tạo profile khi mở màn hình (nếu chưa bind từ login)
Future<void> ensureProfileLoaded(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final provider = context.read<ProfileProvider>();
  if (provider.profile == null && !provider.isLoading) {
    await provider.bindUser(uid,
        email: FirebaseAuth.instance.currentUser?.email);
  }
}
