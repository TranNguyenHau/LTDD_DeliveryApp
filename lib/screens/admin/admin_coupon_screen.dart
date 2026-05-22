import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/firestore_collections.dart';
import '../../models/coupon.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF3B82F6);
  static const _accentEnd = Color(0xFF6366F1);
  static const _danger = Color(0xFFEF4444);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showCouponDialog({Coupon? coupon}) {
    final isEdit = coupon != null;
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final valueCtrl = TextEditingController(text: coupon?.discountValue.toString() ?? '');
    final minOrderCtrl = TextEditingController(text: coupon?.minOrderValue.toString() ?? '0');
    final maxDiscountCtrl = TextEditingController(text: coupon?.maxDiscount.toString() ?? '0');
    final limitCtrl = TextEditingController(text: coupon?.usageLimit.toString() ?? '');
    
    String discountType = coupon?.discountType ?? 'percentage';
    DateTime expiryDate = coupon?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    int perUserLimit = coupon?.perUserLimit ?? 0;
    bool isActive = coupon?.isActive ?? true;
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_accent, _accentEnd]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Icon(isEdit ? Icons.edit : Icons.add_circle, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? "Sửa Voucher" : "Thêm Voucher",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: codeCtrl,
                            label: "Mã Code",
                            hint: "VD: GIAM20",
                            enabled: !isEdit,
                            onChanged: (v) => codeCtrl.text = v.toUpperCase(),
                            validator: (v) => v!.isEmpty ? "Nhập mã code" : null,
                          ),
                          const SizedBox(height: 16),
                          const Text("Loại giảm giá", style: TextStyle(color: _textMuted, fontSize: 13)),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'percentage', label: Text('%'), icon: Icon(Icons.percent)),
                              ButtonSegment(value: 'fixed', label: Text('Cố định'), icon: Icon(Icons.money)),
                            ],
                            selected: {discountType},
                            onSelectionChanged: (val) => setDialogState(() => discountType = val.first),
                            style: SegmentedButton.styleFrom(
                              backgroundColor: _bg,
                              selectedBackgroundColor: _accent,
                              selectedForegroundColor: Colors.white,
                              foregroundColor: _textMuted,
                              side: const BorderSide(color: _border),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: valueCtrl,
                            label: "Giá trị giảm",
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Nhập giá trị" : null,
                          ),
                          const SizedBox(height: 16),
                          if (discountType == 'percentage') ...[
                            _buildTextField(
                              controller: maxDiscountCtrl,
                              label: "Giảm tối đa (đ)",
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildTextField(
                            controller: minOrderCtrl,
                            label: "Đơn tối thiểu (đ)",
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: limitCtrl,
                            label: "Tổng lượt dùng",
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Nhập lượt dùng" : null,
                          ),
                          const SizedBox(height: 16),
                          const Text("Giới hạn mỗi user", style: TextStyle(color: _textMuted, fontSize: 13)),
                          const SizedBox(height: 8),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('Vô hạn')),
                              ButtonSegment(value: 1, label: Text('1 lần')),
                            ],
                            selected: {perUserLimit},
                            onSelectionChanged: (val) => setDialogState(() => perUserLimit = val.first),
                            style: SegmentedButton.styleFrom(
                              backgroundColor: _bg,
                              selectedBackgroundColor: _accent,
                              selectedForegroundColor: Colors.white,
                              foregroundColor: _textMuted,
                              side: const BorderSide(color: _border),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: expiryDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setDialogState(() => expiryDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Hết hạn: ${DateFormat('dd/MM/yyyy').format(expiryDate)}",
                                    style: const TextStyle(color: _text),
                                  ),
                                  const Icon(Icons.calendar_today, color: _accent, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text("Kích hoạt", style: TextStyle(color: _text, fontSize: 15)),
                            value: isActive,
                            activeColor: _accent,
                            onChanged: (v) => setDialogState(() => isActive = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _border),
                            foregroundColor: _textMuted,
                          ),
                          child: const Text("Hủy"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            final couponData = {
                              'discountType': discountType,
                              'discountValue': double.parse(valueCtrl.text),
                              'minOrderValue': double.parse(minOrderCtrl.text),
                              'maxDiscount': double.parse(maxDiscountCtrl.text),
                              'expiryDate': expiryDate.toIso8601String(),
                              'usageLimit': int.parse(limitCtrl.text),
                              'perUserLimit': perUserLimit,
                              'isActive': isActive,
                              'usedCount': coupon?.usedCount ?? 0,
                            };

                            if (isEdit) {
                              await _firestore
                                  .collection(FirestoreCollections.coupons)
                                  .doc(coupon.code)
                                  .update(couponData);
                            } else {
                              await _firestore
                                  .collection(FirestoreCollections.coupons)
                                  .doc(codeCtrl.text.trim().toUpperCase())
                                  .set(couponData);
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(isEdit ? "Cập nhật" : "Tạo mới"),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(color: _text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textMuted.withOpacity(0.5)),
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirm(Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text("Xóa Voucher?", style: TextStyle(color: _text)),
        content: Text("Bạn có chắc muốn xóa mã \"${coupon.code}\"?\nHành động này sẽ hủy kích hoạt mã (Soft Delete).", style: const TextStyle(color: _textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection(FirestoreCollections.coupons).doc(coupon.code).update({'isActive': false});
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text("Quản lý Voucher", style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCouponDialog(),
        backgroundColor: _accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(FirestoreCollections.coupons).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final coupons = snapshot.data!.docs.map((doc) => Coupon.fromFirestore(doc)).toList();

          if (coupons.isEmpty) {
            return const Center(child: Text("Chưa có voucher nào", style: TextStyle(color: _textMuted)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final isExpired = coupon.expiryDate.isBefore(DateTime.now());
              final usagePercent = coupon.usageLimit > 0 ? coupon.usedCount / coupon.usageLimit : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: coupon.isActive ? _border : _danger.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(coupon.code, style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 18)),
                        Switch(
                          value: coupon.isActive,
                          onChanged: (val) => _firestore.collection(FirestoreCollections.coupons).doc(coupon.code).update({'isActive': val}),
                          activeColor: _accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.discountType == 'percentage' 
                        ? "Giảm ${coupon.discountValue}% (Tối đa ${NumberFormat.decimalPattern().format(coupon.maxDiscount)}đ)"
                        : "Giảm ${NumberFormat.decimalPattern().format(coupon.discountValue)}đ",
                      style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: _textMuted, size: 14),
                        const SizedBox(width: 4),
                        Text("Đơn tối thiểu: ${NumberFormat.decimalPattern().format(coupon.minOrderValue)}đ", style: const TextStyle(color: _textMuted, fontSize: 12)),
                        const Spacer(),
                        Icon(Icons.event, color: isExpired ? _danger : _textMuted, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Hết hạn: ${DateFormat('dd/MM/yyyy').format(coupon.expiryDate)}",
                          style: TextStyle(color: isExpired ? _danger : _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: usagePercent,
                              backgroundColor: _bg,
                              color: usagePercent >= 1.0 ? _danger : _accent,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text("${coupon.usedCount}/${coupon.usageLimit}", style: const TextStyle(color: _textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: _border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: _textMuted, size: 20),
                          onPressed: () => _showCouponDialog(coupon: coupon),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: _danger, size: 20),
                          onPressed: () => _showDeleteConfirm(coupon),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
