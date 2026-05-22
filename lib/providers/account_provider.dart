// lib/providers/account_provider.dart
// Provider quản lý danh sách tài khoản (dành cho Admin)

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';
import '../models/account.dart';

class AccountProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Account> _accounts = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _sub;

  List<Account> get accounts => List.unmodifiable(_accounts);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalCount => _accounts.length;
  int get adminCount => _accounts.where((a) => a.isAdmin).length;
  int get userCount => _accounts.where((a) => !a.isAdmin).length;

  /// Bắt đầu lắng nghe realtime
  void startListening() {
    if (_sub != null) return;
    _isLoading = true;
    notifyListeners();

    _sub = _db
        .collection(FirestoreCollections.accounts)
        .orderBy('username')
        .snapshots()
        .listen(
      (snap) {
        _accounts = snap.docs
            .map((doc) => Account.fromMap(doc.data()))
            .toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Không tải được danh sách tài khoản: $e';
        notifyListeners();
      },
    );
  }

  /// Đổi role user ↔ admin
  Future<String?> changeRole(String accountId, String newRole) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _db
          .collection(FirestoreCollections.accounts)
          .doc(accountId)
          .update({'role': newRole});
      return null;
    } catch (e) {
      return 'Đổi quyền thất bại: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Xóa tài khoản khỏi Firestore (không xóa Firebase Auth)
  Future<String?> deleteAccount(String accountId) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _db
          .collection(FirestoreCollections.accounts)
          .doc(accountId)
          .delete();
      // Xóa profile tương ứng nếu có
      await _db
          .collection(FirestoreCollections.users)
          .doc(accountId)
          .delete()
          .catchError((_) {});
      return null;
    } catch (e) {
      return 'Xóa tài khoản thất bại: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Lọc tài khoản theo từ khóa
  List<Account> search(String keyword) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return _accounts;
    return _accounts
        .where((a) =>
            a.username.toLowerCase().contains(q) ||
            a.email.toLowerCase().contains(q) ||
            a.role.toLowerCase().contains(q))
        .toList();
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _accounts = [];
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}