// lib/data/seed_data.dart
// Seed dữ liệu mẫu lên Firestore (chỉ chạy khi collection trống)
// Tài khoản admin/user được tạo qua Firebase Auth — KHÔNG seed account ở đây.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_collections.dart';
import '../models/category.dart';
import '../models/food_item.dart';

/// 4 danh mục theo yêu cầu
final List<Category> seedCategories = [
  const Category(id: 'monchinh', name: 'Món chính', icon: '🍚'),
  const Category(id: 'khaivi', name: 'Khai vị', icon: '🥗'),
  const Category(id: 'trangmieng', name: 'Tráng miệng', icon: '🍮'),
  const Category(id: 'douong', name: 'Đồ uống', icon: '🥤'),
];

/// 10 món ăn Việt Nam đầy đủ thông tin
final List<FoodItem> seedFoods = [
  const FoodItem(
    id: 'food_1',
    name: 'Cơm tấm sườn bì chả',
    description:
    'Cơm tấm thơm ngon với sườn nướng, bì tơi, chả hấp mềm. Ăn kèm nước mắm pha đặc trưng miền Nam.',
    price: 55000,
    imageUrl:
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
    categoryId: 'monchinh',
    rating: 4.8,
    reviewCount: 324,
    prepTimeMinutes: 15,
    isPopular: true,
    tags: ['Bestseller', 'Miền Nam'],
  ),
  const FoodItem(
    id: 'food_2',
    name: 'Phở bò tái chín',
    description:
    'Phở bò truyền thống với nước dùng ninh xương 12 tiếng, thịt bò tái và chín, rau thơm tươi.',
    price: 65000,
    imageUrl:
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=400',
    categoryId: 'monchinh',
    rating: 4.9,
    reviewCount: 512,
    prepTimeMinutes: 10,
    isPopular: true,
    tags: ['Truyền thống'],
  ),
  const FoodItem(
    id: 'food_3',
    name: 'Bún bò Huế',
    description:
    'Bún bò Huế cay đặc trưng với giò heo, chả cua, huyết và sả thơm lừng.',
    price: 60000,
    imageUrl:
    'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400',
    categoryId: 'monchinh',
    rating: 4.6,
    reviewCount: 276,
    prepTimeMinutes: 12,
    isPopular: false,
    tags: ['Cay', 'Huế'],
  ),
  const FoodItem(
    id: 'food_4',
    name: 'Cơm gà xối mỡ',
    description:
    'Gà xối mỡ giòn rụm, da vàng ươm, thịt mềm ngọt ăn kèm cơm trắng và nước chấm.',
    price: 70000,
    imageUrl:
    'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=400',
    categoryId: 'monchinh',
    rating: 4.8,
    reviewCount: 201,
    prepTimeMinutes: 18,
    isPopular: true,
    tags: ['Giòn', 'Ngon'],
  ),
  const FoodItem(
    id: 'food_5',
    name: 'Gỏi cuốn tôm thịt',
    description:
    'Gỏi cuốn tươi với tôm, thịt luộc, bún, rau sống, chấm nước mắm pha hoặc tương đen.',
    price: 45000,
    imageUrl:
    'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400',
    categoryId: 'khaivi',
    rating: 4.7,
    reviewCount: 156,
    prepTimeMinutes: 10,
    isPopular: true,
    tags: ['Tươi', 'Healthy'],
  ),
  const FoodItem(
    id: 'food_6',
    name: 'Nem nướng Nha Trang',
    description:
    'Nem nướng thơm lừng cuốn bánh tráng, rau sống, chấm nước chấm đặc biệt.',
    price: 50000,
    imageUrl:
    'https://images.unsplash.com/photo-1604908176997-431658f68f51?w=400',
    categoryId: 'khaivi',
    rating: 4.5,
    reviewCount: 98,
    prepTimeMinutes: 12,
    isPopular: false,
    tags: ['Nha Trang'],
  ),
  const FoodItem(
    id: 'food_7',
    name: 'Bánh flan caramen',
    description:
    'Bánh flan mềm mịn với nước caramel thơm ngon, ăn lạnh rất ngon.',
    price: 25000,
    imageUrl:
    'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
    categoryId: 'trangmieng',
    rating: 4.4,
    reviewCount: 87,
    prepTimeMinutes: 0,
    isPopular: false,
    tags: ['Ngọt', 'Mát'],
  ),
  const FoodItem(
    id: 'food_8',
    name: 'Chè đậu xanh',
    description:
    'Chè đậu xanh nấu nhừ, thêm cốt dừa và đá tươi mát, vị ngọt thanh.',
    price: 20000,
    imageUrl:
    'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400',
    categoryId: 'trangmieng',
    rating: 4.6,
    reviewCount: 134,
    prepTimeMinutes: 5,
    isPopular: true,
    tags: ['Giải nhiệt'],
  ),
  const FoodItem(
    id: 'food_9',
    name: 'Trà sữa trân châu',
    description:
    'Trà sữa thơm ngon với trân châu đen dai ngon, đường vừa phải theo yêu cầu.',
    price: 40000,
    imageUrl:
    'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?w=400',
    categoryId: 'douong',
    rating: 4.7,
    reviewCount: 389,
    prepTimeMinutes: 5,
    isPopular: true,
    tags: ['Hot', 'Giải khát'],
  ),
  const FoodItem(
    id: 'food_10',
    name: 'Cà phê sữa đá',
    description:
    'Cà phê phin đậm đà pha với sữa đặc, đá viên mát lạnh — hương vị Sài Gòn.',
    price: 30000,
    imageUrl:
    'https://images.unsplash.com/photo-1514432324607-09f9a6badc7e?w=400',
    categoryId: 'douong',
    rating: 4.8,
    reviewCount: 245,
    prepTimeMinutes: 5,
    isPopular: true,
    tags: ['Cà phê', 'Việt Nam'],
  ),
];

Future<bool> _collectionHasData(String collection) async {
  final snap = await FirebaseFirestore.instance
      .collection(collection)
      .limit(1)
      .get();
  return snap.docs.isNotEmpty;
}

Future<void> _writeCategories() async {
  if (await _collectionHasData(FirestoreCollections.categories)) return;
  final batch = FirebaseFirestore.instance.batch();
  for (final cat in seedCategories) {
    final ref = FirebaseFirestore.instance
        .collection(FirestoreCollections.categories)
        .doc(cat.id);
    batch.set(ref, cat.toMap());
  }
  await batch.commit();
}

Future<void> _writeFoods() async {
  if (await _collectionHasData(FirestoreCollections.foods)) return;
  final batch = FirebaseFirestore.instance.batch();
  for (final food in seedFoods) {
    final ref = FirebaseFirestore.instance
        .collection(FirestoreCollections.foods)
        .doc(food.id);
    batch.set(ref, food.toMap());
  }
  await batch.commit();
}

/// Chỉ seed categories và foods — accounts tự tạo khi login lần đầu
Future<void> seedAll() async {
  await _writeCategories();
  await _writeFoods();
}