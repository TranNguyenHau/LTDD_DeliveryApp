// lib/data/mock_data.dart

import '../models/category.dart';
import '../models/food_item.dart';

const List<Category> mockCategories = [
  Category(id: 'all', name: 'Tất cả', icon: '🍽️'),
  Category(id: 'com', name: 'Cơm', icon: '🍚'),
  Category(id: 'pho', name: 'Phở', icon: '🍜'),
  Category(id: 'banh', name: 'Bánh', icon: '🥐'),
  Category(id: 'nuoc', name: 'Nước', icon: '🥤'),
  Category(id: 'trangmieng', name: 'Tráng miệng', icon: '🍮'),
];

const List<FoodItem> mockFoods = [
  FoodItem(
    id: '1',
    name: 'Cơm tấm sườn bì chả',
    description:
        'Cơm tấm thơm ngon với sườn nướng, bì tơi, chả hấp mềm. Ăn kèm nước mắm pha đặc trưng miền Nam.',
    price: 55000,
    imageUrl:
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
    categoryId: 'com',
    rating: 4.8,
    reviewCount: 324,
    prepTimeMinutes: 15,
    isPopular: true,
    tags: ['Bestseller', 'Miền Nam'],
  ),
  FoodItem(
    id: '2',
    name: 'Phở bò tái chín',
    description:
        'Phở bò truyền thống với nước dùng ninh xương 12 tiếng, thịt bò tái và chín, rau thơm tươi.',
    price: 65000,
    imageUrl:
        'https://images.unsplash.com/photo-1544025162-d76694265947?w=400',
    categoryId: 'pho',
    rating: 4.9,
    reviewCount: 512,
    prepTimeMinutes: 10,
    isPopular: true,
    tags: ['Truyền thống'],
  ),
  FoodItem(
    id: '3',
    name: 'Bánh mì thịt đặc biệt',
    description:
        'Bánh mì giòn với jambon, chả lụa, pate, dưa leo, rau mùi và tương ớt đặc biệt.',
    price: 35000,
    imageUrl:
        'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400',
    categoryId: 'banh',
    rating: 4.7,
    reviewCount: 198,
    prepTimeMinutes: 5,
    isPopular: true,
    tags: ['Nhanh', 'Rẻ'],
  ),
  FoodItem(
    id: '4',
    name: 'Bún bò Huế',
    description:
        'Bún bò Huế cay đặc trưng với giò heo, chả cua, huyết và sả thơm lừng.',
    price: 60000,
    imageUrl:
        'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400',
    categoryId: 'pho',
    rating: 4.6,
    reviewCount: 276,
    prepTimeMinutes: 12,
    isPopular: false,
    tags: ['Cay', 'Huế'],
  ),
  FoodItem(
    id: '5',
    name: 'Cơm chiên dương châu',
    description:
        'Cơm chiên thơm với tôm, trứng, xúc xích, đậu hà lan và hành lá.',
    price: 50000,
    imageUrl:
        'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
    categoryId: 'com',
    rating: 4.5,
    reviewCount: 142,
    prepTimeMinutes: 20,
    isPopular: false,
    tags: ['Phổ biến'],
  ),
  FoodItem(
    id: '6',
    name: 'Trà sữa trân châu',
    description:
        'Trà sữa thơm ngon với trân châu đen dai ngon, đường vừa phải theo yêu cầu.',
    price: 40000,
    imageUrl:
        'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?w=400',
    categoryId: 'nuoc',
    rating: 4.7,
    reviewCount: 389,
    prepTimeMinutes: 5,
    isPopular: true,
    tags: ['Hot', 'Giải khát'],
  ),
  FoodItem(
    id: '7',
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
  FoodItem(
    id: '8',
    name: 'Cơm gà xối mỡ',
    description:
        'Gà xối mỡ giòn rụm, da vàng ươm, thịt mềm ngọt ăn kèm cơm trắng và nước chấm.',
    price: 70000,
    imageUrl:
        'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=400',
    categoryId: 'com',
    rating: 4.8,
    reviewCount: 201,
    prepTimeMinutes: 18,
    isPopular: true,
    tags: ['Giòn', 'Ngon'],
  ),
  
];
