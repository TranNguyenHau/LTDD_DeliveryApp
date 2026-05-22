// lib/models/account.dart
// Tài khoản người dùng lưu trên Firestore (gắn với Firebase Auth uid)

class Account {
  final String id;
  final String username;
  final String email;
  final String role; // 'admin' | 'user'

  const Account({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
    );
  }
}

/// Alias giữ tương thích code cũ (login.dart import UserModel)
typedef UserModel = Account;
