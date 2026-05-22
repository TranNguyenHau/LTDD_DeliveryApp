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
  /// Nếu doc chưa tồn tại → tự tạo (fix trường hợp seed cũ bị lệch UID).
  Future<Account> signIn({
    required String username,
    required String password,
  }) async {
    final email = '${username.trim().toLowerCase()}@foodapp.local';

    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    // Đọc doc Firestore
    var account = await _fetchAccount(uid);

    // Nếu chưa có doc → tự tạo dựa trên thông tin Auth
    if (account == null) {
      // Xác định role: admin nếu username là 'admin'
      final role = username.trim().toLowerCase() == 'admin' ? 'admin' : 'customer';
      account = Account(
        id: uid,
        username: username.trim().toLowerCase(),
        email: email,
        role: role,
      );
      await _db
          .collection(FirestoreCollections.accounts)
          .doc(uid)
          .set(account.toMap());
    }

    return account;
  }

  /// Đăng ký: tạo user Auth + document accounts
  Future<Account> register({
    required String username,
    required String password,
  }) async {
    final email = '${username.trim().toLowerCase()}@foodapp.local';

    // Kiểm tra username trùng
    final existing = await _db
        .collection(FirestoreCollections.accounts)
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Username đã tồn tại.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final account = Account(
      id: cred.user!.uid,
      username: username.trim().toLowerCase(),
      email: email,
      role: 'customer',
    );

    await _db
        .collection(FirestoreCollections.accounts)
        .doc(cred.user!.uid)
        .set(account.toMap());

    final profile = UserProfile.initial(
      id: cred.user!.uid,
      email: email,
      fullName: username.trim(),
    );
    await _db
        .collection(FirestoreCollections.users)
        .doc(cred.user!.uid)
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