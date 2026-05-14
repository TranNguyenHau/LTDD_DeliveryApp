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
}
