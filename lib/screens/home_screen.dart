// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as food_category;
import '../providers/food_provider.dart';
import '../widgets/food_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/cart_badge.dart';
import 'food_detail_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = context.watch<FoodProvider>();
    final filteredFoods = foodProvider.filteredFoods;
    final popularFoods = foodProvider.popularFoods;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào! 👋',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          const Text(
                            'Bạn muốn ăn gì hôm nay?',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    CartBadge(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()))),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) =>
                      context.read<FoodProvider>().setSearchQuery(q),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ăn...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: foodProvider.categories
                        .map<Widget>((food_category.Category cat) => CategoryChip(
                              label: cat.name,
                              icon: cat.icon,
                              isSelected:
                                  foodProvider.selectedCategoryId == cat.id,
                              onTap: () => context
                                  .read<FoodProvider>()
                                  .selectCategory(cat.id),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),

            // Popular section
            if (foodProvider.searchQuery.isEmpty &&
                foodProvider.selectedCategoryId == 'all') ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Món phổ biến 🔥',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: popularFoods.length,
                    itemBuilder: (ctx, i) => SizedBox(
                      width: 160,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FoodCard(
                          food: popularFoods[i],
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FoodDetailScreen(
                                      food: popularFoods[i]))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // All foods header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  foodProvider.searchQuery.isNotEmpty
                      ? 'Kết quả tìm kiếm (${filteredFoods.length})'
                      : 'Tất cả món ăn',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: filteredFoods.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            const Text('🍽️',
                                style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Không tìm thấy món ăn',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => FoodCard(
                          food: filteredFoods[i],
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FoodDetailScreen(
                                      food: filteredFoods[i]))),
                        ),
                        childCount: filteredFoods.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
