// lib/screens/profile_screen.dart
// Màn hình hồ sơ khách hàng — xem và chỉnh sửa thông tin

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  DateTime? _lastSyncedAt;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  /// Đồng bộ form với dữ liệu Firestore (tránh ghi đè khi user đang gõ)
  void _syncControllers(UserProfile profile) {
    if (_lastSyncedAt == profile.updatedAt) return;
    _fullNameCtrl.text = profile.fullName;
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
    _addressCtrl.text = profile.address;
    _lastSyncedAt = profile.updatedAt;
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
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack('Cập nhật ảnh đại diện thành công!');
    }
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
      _showSnack('Lưu hồ sơ thành công!');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
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
    final primary = Theme.of(context).primaryColor;

    // Đồng bộ form khi có dữ liệu từ Firestore
    if (profile != null) {
      _syncControllers(profile);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: profileProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            )
          : profile == null
              ? Center(
                  child: Text(
                    profileProvider.errorMessage ?? 'Không tải được hồ sơ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar
                        _AvatarSection(
                          avatarUrl: profile.avatarUrl,
                          isUploading: profileProvider.isUploadingAvatar,
                          onTap: profileProvider.isUploadingAvatar
                              ? null
                              : _pickAndUploadAvatar,
                        ),
                        const SizedBox(height: 24),

                        // Form fields
                        _buildField(
                          controller: _fullNameCtrl,
                          label: 'Họ và tên',
                          icon: Icons.person_outline,
                          validator: AppValidators.fullName,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          readOnly: true,
                          validator: AppValidators.email,
                          helperText: 'Email gắn với tài khoản đăng nhập',
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Số điện thoại',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: AppValidators.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _addressCtrl,
                          label: 'Địa chỉ giao hàng',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: AppValidators.address,
                        ),
                        const SizedBox(height: 28),

                        // Nút lưu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: profileProvider.isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: profileProvider.isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Lưu thay đổi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? Colors.grey[600] : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Widget hiển thị avatar + nút đổi ảnh
class _AvatarSection extends StatelessWidget {
  final String avatarUrl;
  final bool isUploading;
  final VoidCallback? onTap;

  const _AvatarSection({
    required this.avatarUrl,
    required this.isUploading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Icon(Icons.person, size: 56, color: Colors.grey[400])
                    : null,
              ),
              if (isUploading)
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: const Text('Đổi ảnh đại diện'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Khởi tạo profile khi mở màn hình (nếu chưa bind từ login)
Future<void> ensureProfileLoaded(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final provider = context.read<ProfileProvider>();
  if (provider.profile == null && !provider.isLoading) {
    await provider.bindUser(
      uid,
      email: FirebaseAuth.instance.currentUser?.email,
    );
  }
}
