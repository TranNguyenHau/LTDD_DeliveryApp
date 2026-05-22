import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_app/models/food_item.dart';
import 'package:food_app/providers/food_provider.dart';
import 'package:food_app/models/category.dart' as food_category;

import 'package:food_app/screens/main_shell.dart';
import 'package:food_app/screens/admin/admin_order_screen.dart';
import 'package:food_app/screens/admin/admin_account_screen.dart';
import 'package:food_app/screens/admin/admin_stats_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // ───────────────── Palette ─────────────────
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _card = Color(0xFF1A2744);
  static const _accent = Color(0xFF3B82F6);
  static const _accentEnd = Color(0xFF6366F1);
  static const _danger = Color(0xFFEF4444);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);

  // ───────────────── Add/Edit Food Dialog ─────────────────
  void showFoodDialog({FoodItem? food}) {
    final isEdit = food != null;

    final nameCtrl = TextEditingController(text: food?.name ?? '');
    final priceCtrl =
        TextEditingController(text: food?.price.toString() ?? '');
    final imageCtrl =
        TextEditingController(text: food?.imageUrl ?? '');
    final descCtrl =
        TextEditingController(text: food?.description ?? '');

    final formKey = GlobalKey<FormState>();

    String selectedCategoryId =
        food?.categoryId ?? 'monchinh';

    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accent, _accentEnd],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.add_circle_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEdit
                                ? "Chỉnh sửa món ăn"
                                : "Thêm món ăn",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              _dialogField(
                                controller: nameCtrl,
                                label: "Tên món",
                                icon: Icons.restaurant_menu_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Nhập tên món";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              _dialogField(
                                controller: priceCtrl,
                                label: "Giá",
                                icon: Icons.payments_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Nhập giá";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              DropdownButtonFormField<String>(
                                value: selectedCategoryId,
                                dropdownColor: _surface,
                                style: const TextStyle(color: _text),
                                decoration: _inputDecoration(
                                  "Danh mục",
                                  Icons.category_rounded,
                                ),
                                items: context
                                    .read<FoodProvider>()
                                    .categories
                                    .where((cat) => cat.id != 'all')
                                    .map(
                                      (food_category.Category cat) =>
                                          DropdownMenuItem(
                                        value: cat.id,
                                        child: Text(cat.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedCategoryId = value;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 16),

                              _dialogField(
                                controller: imageCtrl,
                                label: "Link ảnh",
                                icon: Icons.image_rounded,
                              ),

                              const SizedBox(height: 16),

                              _dialogField(
                                controller: descCtrl,
                                label: "Mô tả",
                                icon: Icons.notes_rounded,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textMuted,
                                side:
                                    const BorderSide(color: _border),
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text("Hủy"),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: dialogLoading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!
                                          .validate()) {
                                        return;
                                      }

                                      setDialogState(() {
                                        dialogLoading = true;
                                      });

                                      final provider =
                                          context.read<FoodProvider>();

                                      final newFood = FoodItem(
                                        id: food?.id ??
                                            "food_${DateTime.now().millisecondsSinceEpoch}",
                                        name:
                                            nameCtrl.text.trim(),
                                        description:
                                            descCtrl.text.trim(),
                                        price: double.tryParse(
                                                  priceCtrl.text,
                                                ) ??
                                                0,
                                        imageUrl:
                                            imageCtrl.text.trim(),
                                        categoryId:
                                            selectedCategoryId,
                                        rating:
                                            food?.rating ?? 4.5,
                                        reviewCount:
                                            food?.reviewCount ?? 0,
                                        prepTimeMinutes:
                                            food?.prepTimeMinutes ??
                                                15,
                                        isPopular:
                                            food?.isPopular ??
                                                false,
                                        tags: food?.tags ?? [],
                                      );

                                      final error = isEdit
                                          ? await provider
                                              .updateFood(
                                                  newFood)
                                          : await provider
                                              .addFood(newFood);

                                      if (!context.mounted) {
                                        return;
                                      }

                                      setDialogState(() {
                                        dialogLoading = false;
                                      });

                                      if (error != null) {
                                        _showError(error);
                                        return;
                                      }

                                      Navigator.pop(context);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: dialogLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEdit
                                          ? "Lưu"
                                          : "Thêm món",
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────── Delete Dialog ─────────────────
  void showDeleteDialog(FoodItem food) {
    bool loading = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Xóa món ăn",
                style: TextStyle(color: _text),
              ),
              content: Text(
                "Bạn chắc chắn muốn xóa \"${food.name}\" ?",
                style: const TextStyle(color: _textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setDialogState(() {
                            loading = true;
                          });

                          final error = await context
                              .read<FoodProvider>()
                              .deleteFood(food.id);

                          if (!context.mounted) return;

                          if (error != null) {
                            _showError(error);

                            setDialogState(() {
                              loading = false;
                            });

                            return;
                          }

                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _danger,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Xóa"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────── Food Management ─────────────────
  Widget _buildFoodManagementSection(
    FoodProvider provider,
    List<FoodItem> foods,
  ) {
    return Column(
      children: [
        // Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: _accent,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Tổng món ăn",
                    style: TextStyle(
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                "${foods.length} món",
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                  ),
                )
              : GridView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    100,
                  ),
                  itemCount: foods.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final food = foods[index];

                    return _FoodCard(
                      food: food,
                      onEdit: () {
                        showFoodDialog(food: food);
                      },
                      onDelete: () {
                        showDeleteDialog(food);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ───────────────── Helpers ─────────────────
  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: _textMuted),
      prefixIcon:
          Icon(icon, color: _textMuted),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: _accent),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: _text),
      decoration:
          _inputDecoration(label, icon),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: _danger,
        content: Text(message),
      ),
    );
  }

  // ───────────────── Build ─────────────────
  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<FoodProvider>();

    final foods = provider.foods;

    final pages = [
      _buildFoodManagementSection(
          provider, foods),
      const AdminOrderScreen(),
      const AdminStatsScreen(),
      const AdminAccountScreen(),
    ];

    final titles = [
      "Quản lý món ăn",
      "Quản lý đơn hàng",
      "Thống kê doanh thu",
      "Quản lý tài khoản",
    ];

    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _text,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MainShell(),
                ),
              );
            },
            icon: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              "Cửa hàng",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                  backgroundColor: _accent,
                  foregroundColor:
                      Colors.white,
                  onPressed: () {
                    showFoodDialog();
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label:
                      const Text("Thêm món"),
                )
              : null,

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar:
          BottomNavigationBar(
        backgroundColor: _surface,
        currentIndex: _selectedIndex,
        selectedItemColor: _accent,
        unselectedItemColor:
            _textMuted,
        type:
            BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.restaurant_menu_rounded,
            ),
            label: "Món ăn",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.local_shipping_rounded,
            ),
            label: "Đơn hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.bar_chart_rounded,
            ),
            label: "Thống kê",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.manage_accounts_rounded,
            ),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}

// ───────────────── Food Card ─────────────────
class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodCard({
    required this.food,
    required this.onEdit,
    required this.onDelete,
  });

  static const _surface =
      Color(0xFF1A2744);

  static const _border =
      Color(0xFF2D3F5C);

  static const _text =
      Colors.white;

  static const _textMuted =
      Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(color: _border),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                food.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return Container(
                    color:
                        Colors.grey.shade800,
                    child: const Icon(
                      Icons.broken_image,
                      color: _textMuted,
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: Padding(
              padding:
                  const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${food.price.toInt()} đ",
                    style: const TextStyle(
                      color:
                          Color(0xFF34D399),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: "Sửa",
                          icon:
                              Icons.edit_rounded,
                          color:
                              Colors.blue,
                          onTap: onEdit,
                        ),
                      ),

                      const SizedBox(
                          width: 8),

                      Expanded(
                        child: _ActionBtn(
                          label: "Xóa",
                          icon:
                              Icons.delete_rounded,
                          color:
                              Colors.red,
                          onTap: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── Action Button ─────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}