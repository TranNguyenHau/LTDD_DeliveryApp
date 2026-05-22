// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_collections.dart';
import '../models/account.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Đăng nhập: dùng Firebase Auth, sau đó đọc doc Firestore.
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    // Đọc doc Firestore
    var account = await _fetchAccount(uid);

    // Nếu chưa có doc → tự tạo dựa trên thông tin Auth
    if (account == null) {
      // Xác định role: admin nếu email chứa 'admin'
      final role = email.trim().toLowerCase().contains('admin') ? 'admin' : 'customer';
      account = Account(
        id: uid,
        username: email.split('@')[0],
        email: email.trim(),
        role: role,
      );
      await _db
          .collection(FirestoreCollections.accounts)
          .doc(uid)
          .set(account.toMap());
    }

    return account;
  }

  /// Đăng ký: tạo user Auth + document accounts + profile sơ khởi
  Future<Account> register({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    final account = Account(
      id: uid,
      username: email.split('@')[0],
      email: email.trim(),
      role: 'customer',
    );

    await _db
        .collection(FirestoreCollections.accounts)
        .doc(uid)
        .set(account.toMap());

    final profile = UserProfile.initial(
      id: uid,
      email: email.trim(),
      fullName: '', // Sẽ cập nhật ở bước sau trong UI đăng ký
    );
    await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(profile.toMap());

    return account;
  }

  Future<void> signOut() => _auth.signOut();

  Future<Account?> _fetchAccount(String uid) async {
    final doc =
    await _db.collection(FirestoreCollections.accounts).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Account.fromMap(doc.data()!);
  }
}
