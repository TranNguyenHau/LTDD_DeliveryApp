// lib/models/user_profile.dart
// Hồ sơ khách hàng lưu trên collection "users"

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.fullName = '',
    required this.email,
    this.phone = '',
    this.address = '',
    this.avatarUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Tạo profile mặc định khi đăng ký
  factory UserProfile.initial({
    required String id,
    required String email,
    String fullName = '',
    String phone = '',
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
