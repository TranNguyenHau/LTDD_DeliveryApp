// lib/models/category.dart

class Category {
  final String id;
  final String name;
  final String icon;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  /// Chuyển đối tượng sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  /// Tạo Category từ dữ liệu Firestore
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '🍽️',
    );
  }

  /// Danh mục ảo "Tất cả" — chỉ dùng trên UI, không lưu Firestore
  static const Category all = Category(id: 'all', name: 'Tất cả', icon: '🍽️');
}
