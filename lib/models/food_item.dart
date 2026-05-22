// lib/models/food_item.dart

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final double rating;
  final int reviewCount;
  final int prepTimeMinutes;
  final bool isPopular;
  final List<String> tags;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.prepTimeMinutes = 20,
    this.isPopular = false,
    this.tags = const [],
  });

  /// Chuyển đối tượng sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'rating': rating,
      'reviewCount': reviewCount,
      'prepTimeMinutes': prepTimeMinutes,
      'isPopular': isPopular,
      'tags': tags,
    };
  }

  /// Tạo FoodItem từ dữ liệu Firestore
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      prepTimeMinutes: (map['prepTimeMinutes'] as num?)?.toInt() ?? 20,
      isPopular: map['isPopular'] as bool? ?? false,
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Tạo bản sao với một số trường thay đổi
  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? categoryId,
    double? rating,
    int? reviewCount,
    int? prepTimeMinutes,
    bool? isPopular,
    List<String>? tags,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
    );
  }
}
