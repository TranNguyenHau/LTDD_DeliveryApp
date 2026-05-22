// lib/providers/profile_provider.dart
// Đọc/ghi hồ sơ khách hàng từ Firestore collection "users"

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/user_profile.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserProfile? _profile;
  String? _userId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;

  /// Gắn user và lắng nghe thay đổi realtime từ Firestore
  Future<void> bindUser(String userId, {String? email, String? fullName}) async {
    if (_userId == userId && _profileSub != null) return;

    await _profileSub?.cancel();
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Đảm bảo document tồn tại
    await _ensureProfileDoc(userId, email: email, fullName: fullName);

    _profileSub = _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .snapshots()
        .listen(
      (snap) {
        if (snap.exists && snap.data() != null) {
          _profile = UserProfile.fromMap(snap.data()!);
          _errorMessage = null;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Không tải được hồ sơ: $e';
        notifyListeners();
      },
    );
  }

  /// Tạo document users nếu chưa có (đăng ký / đăng nhập lần đầu)
  Future<void> _ensureProfileDoc(
    String userId, {
    String? email,
    String? fullName,
  }) async {
    final ref = _db.collection(FirestoreCollections.users).doc(userId);
    final doc = await ref.get();
    if (!doc.exists) {
      final profile = UserProfile.initial(
        id: userId,
        email: email ?? '',
        fullName: fullName ?? '',
      );
      await ref.set(profile.toMap());
    }
  }

  /// Cập nhật thông tin profile
  Future<String?> updateProfile({
    required String fullName,
    required String phone,
    required String address,
  }) async {
    if (_userId == null || _profile == null) {
      return 'Chưa có thông tin người dùng';
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = _profile!.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        address: address.trim(),
        updatedAt: DateTime.now(),
      );

      await _db
          .collection(FirestoreCollections.users)
          .doc(_userId)
          .update(updated.toMap());

      return null;
    } catch (e) {
      _errorMessage = 'Lưu thất bại: $e';
      return _errorMessage;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Upload ảnh đại diện lên Firebase Storage và cập nhật URL
  Future<String?> uploadAvatar(File imageFile) async {
    if (_userId == null) return 'Chưa đăng nhập';

    _isUploadingAvatar = true;
    notifyListeners();

    try {
      final ref = _storage.ref().child('avatars/$_userId.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _db.collection(FirestoreCollections.users).doc(_userId).update({
        'avatarUrl': downloadUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return null;
    } catch (e) {
      return 'Upload ảnh thất bại: $e';
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  /// Hủy lắng nghe khi đăng xuất
  Future<void> clear() async {
    await _profileSub?.cancel();
    _profileSub = null;
    _userId = null;
    _profile = null;
    _isLoading = false;
    _isSaving = false;
    _isUploadingAvatar = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
