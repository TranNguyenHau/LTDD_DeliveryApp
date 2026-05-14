import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/screens/home_screen.dart';

import 'package:food_app/models/food_item.dart';
import 'package:food_app/providers/food_provider.dart';
import 'package:food_app/models/category.dart' as food_category;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // ─── Palette ───────────────────────────────────────────────
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _card = Color(0xFF1A2744);
  static const _accent = Color(0xFF3B82F6);
  static const _accentEnd = Color(0xFF6366F1);
  static const _danger = Color(0xFFEF4444);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);

  // ─── Dialog ────────────────────────────────────────────────
  void showFoodDialog({FoodItem? food}) {
    final nameCtrl = TextEditingController(text: food?.name ?? '');
    final priceCtrl = TextEditingController(text: food?.price.toString() ?? '');
    final imageCtrl = TextEditingController(text: food?.imageUrl ?? '');
    final descCtrl = TextEditingController(text: food?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = food != null;
    String selectedCategoryId = food?.categoryId ?? 'com'; // Default to 'com'

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accent, _accentEnd],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? "Chỉnh sửa món ăn" : "Thêm món mới",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
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
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? "Vui lòng nhập tên món" : null,
                          ),
                          const SizedBox(height: 16),
                          _dialogField(
                            controller: priceCtrl,
                            label: "Giá (đ)",
                            icon: Icons.payments_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? "Vui lòng nhập giá" : null,
                          ),
                          const SizedBox(height: 16),
                          // Category dropdown
                          DropdownButtonFormField<String>(
                            value: selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: "Danh mục",
                              labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
                              prefixIcon: const Icon(Icons.category_rounded, color: _textMuted, size: 20),
                              filled: true,
                              fillColor: _bg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _accent, width: 1.5),
                              ),
                            ),
                            dropdownColor: _surface,
                            style: const TextStyle(color: _text, fontSize: 15),
                            items: context.read<FoodProvider>().categories
                                .where((cat) => cat.id != 'all') // Exclude 'Tất cả'
                                .map((food_category.Category cat) => DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(cat.name, style: const TextStyle(color: _text)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCategoryId = value;
                                });
                              }
                            },
                            validator: (value) =>
                                value == null ? "Vui lòng chọn danh mục" : null,
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

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _border),
                          foregroundColor: _textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Hủy", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_accent, _accentEnd]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final provider = context.read<FoodProvider>();
                            final newFood = FoodItem(
                              id: food?.id ??
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameCtrl.text,
                              description: descCtrl.text,
                              price: double.tryParse(priceCtrl.text) ?? 0,
                              imageUrl: imageCtrl.text,
                              categoryId: selectedCategoryId,
                              rating: food?.rating ?? 4.5,
                              reviewCount: food?.reviewCount ?? 0,
                              prepTimeMinutes: food?.prepTimeMinutes ?? 15,
                              isPopular: food?.isPopular ?? false,
                              tags: food?.tags ?? [],
                            );
                            if (isEdit) {
                              provider.updateFood(newFood);
                            } else {
                              provider.addFood(newFood);
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEdit ? "Lưu thay đổi" : "Thêm món",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ─── Delete confirm dialog ──────────────────────────────────
  void showDeleteDialog(FoodItem food) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: _danger, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Xóa món ăn?",
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bạn có chắc muốn xóa \"${food.name}\"?\nHành động này không thể hoàn tác.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textMuted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _border),
                        foregroundColor: _textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Hủy", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<FoodProvider>().deleteFood(food.id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Xóa",
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper: dialog text field ──────────────────────────────
  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: _text, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: _textMuted, size: 20),
        filled: true,
        fillColor: _bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger),
        ),
        errorStyle: const TextStyle(color: _danger, fontSize: 11),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final foods = context.watch<FoodProvider>().filteredFoods;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Quản lý món ăn",
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
            icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Cửa hàng',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.3)),
            ),
            child: Text(
              "${foods.length} món",
              style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFoodDialog(),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Thêm món", style: TextStyle(fontWeight: FontWeight.w700)),
      ),

      body: foods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      size: 72, color: _textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có món ăn nào",
                    style: TextStyle(color: _textMuted, fontSize: 16),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: foods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) {
                final food = foods[index];
                return _FoodCard(
                  food: food,
                  onEdit: () => showFoodDialog(food: food),
                  onDelete: () => showDeleteDialog(food),
                );
              },
            ),
    );
  }
}

// ─── Food Card ────────────────────────────────────────────────
class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodCard({
    required this.food,
    required this.onEdit,
    required this.onDelete,
  });

  static const _surface = Color(0xFF1A2744);
  static const _border = Color(0xFF2D3F5C);
  static const _accent = Color(0xFF3B82F6);
  static const _accentEnd = Color(0xFF6366F1);
  static const _danger = Color(0xFFEF4444);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.network(
                    food.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0F172A),
                      child: const Icon(Icons.broken_image_rounded,
                          color: _textMuted, size: 40),
                    ),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        food.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${food.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ",
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: "Sửa",
                          icon: Icons.edit_rounded,
                          gradient: const [_accent, _accentEnd],
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionBtn(
                          label: "Xóa",
                          icon: Icons.delete_rounded,
                          gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}