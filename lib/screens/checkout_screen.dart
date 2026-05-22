// lib/screens/checkout_screen.dart
// Màn hình xác nhận đặt hàng
// - Tự động lấy địa chỉ từ profile nếu có
// - Cho phép chọn địa chỉ khác (đặt hộ bạn, địa chỉ tạm)
// - Cho phép lưu địa chỉ mới vào profile
// Style tham khảo GrabFood / ShopeeFood

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/profile_provider.dart';
import 'order_success_screen.dart';

// ─── Address option types ─────────────────────────────────
enum _AddressType {
  profile, // Địa chỉ từ profile
  custom,  // Địa chỉ khác do user nhập
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  // ─── Theme ───────────────────────────────────────────────
  static const _orange = Color(0xFFFF6B00);
  static const _bg = Color(0xFFF5F5F5);
  static const _surface = Colors.white;
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF9E9E9E);
  static const _border = Color(0xFFEEEEEE);
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

  // ─── State ───────────────────────────────────────────────
  _AddressType _addressType = _AddressType.profile;
  final _customAddressCtrl = TextEditingController();
  bool _saveAddressToProfile = false;
  int _paymentMethod = 0; // 0: Cash, 1: E-wallet
  bool _isPlacing = false;
  bool _addressInitialized = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _customAddressCtrl.dispose();
    super.dispose();
  }

  /// Địa chỉ sẽ dùng để đặt hàng
  String get _deliveryAddress {
    if (_addressType == _AddressType.profile) {
      final addr = context.read<ProfileProvider>().profile?.address ?? '';
      return addr;
    }
    return _customAddressCtrl.text.trim();
  }

  String _formatPrice(double price) {
    return price
        .toInt()
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  Future<void> _placeOrder(CartProvider cart, double total) async {
    // Validate địa chỉ
    final address = _deliveryAddress;
    if (address.isEmpty) {
      _showSnack('Vui lòng nhập địa chỉ giao hàng', isError: true);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnack('Vui lòng đăng nhập để đặt hàng', isError: true);
      return;
    }

    setState(() => _isPlacing = true);

    // Lưu địa chỉ vào profile nếu user chọn
    if (_addressType == _AddressType.custom &&
        _saveAddressToProfile &&
        address.isNotEmpty) {
      final profileProvider = context.read<ProfileProvider>();
      final currentProfile = profileProvider.profile;
      if (currentProfile != null) {
        await profileProvider.updateProfile(
          fullName: currentProfile.fullName,
          phone: currentProfile.phone,
          address: address,
        );
      }
    }

    final order = await context.read<OrderProvider>().placeOrder(
          userId: uid,
          items: cart.items.values.toList(),
          totalAmount: total,
          deliveryAddress: address,
        );

    if (!mounted) return;
    setState(() => _isPlacing = false);

    if (order == null) {
      final err = context.read<OrderProvider>().errorMessage;
      _showSnack(err ?? 'Đặt hàng thất bại', isError: true);
      return;
    }

    context.read<CartProvider>().clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final profileAddress = profile?.address ?? '';
    final double subtotal = cart.totalAmount;
    const double deliveryFee = 15000;
    final double total = subtotal + deliveryFee;

    // Khởi tạo: nếu profile có địa chỉ → mặc định dùng profile
    // nếu không → mặc định sang custom
    if (!_addressInitialized) {
      _addressInitialized = true;
      if (profileAddress.isEmpty) {
        _addressType = _AddressType.custom;
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Xác nhận đặt hàng',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _textDark),
        ),
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── 1. Địa chỉ giao hàng ──────────────────────
              _buildAddressSection(profileAddress),
              const SizedBox(height: 12),

              // ── 2. Phương thức thanh toán ──────────────────
              _buildPaymentSection(),
              const SizedBox(height: 12),

              // ── 3. Tóm tắt đơn hàng ───────────────────────
              _buildOrderSummary(cart, subtotal, deliveryFee, total),
              const SizedBox(height: 24),

              // ── 4. Nút đặt hàng ───────────────────────────
              _buildPlaceOrderButton(cart, total),
              const SizedBox(height: 12),

              // Note
              const Center(
                child: Text(
                  'Bằng cách đặt hàng, bạn đồng ý với điều khoản dịch vụ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _textMuted),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Address section ──────────────────────────────────────
  Widget _buildAddressSection(String profileAddress) {
    final hasProfileAddress = profileAddress.isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, size: 18, color: _orange),
              ),
              const SizedBox(width: 10),
              const Text(
                'Địa chỉ giao hàng',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Option 1: Profile address (chỉ hiện nếu có)
          if (hasProfileAddress) ...[
            _addressOption(
              isSelected: _addressType == _AddressType.profile,
              onTap: () => setState(() => _addressType = _AddressType.profile),
              child: _profileAddressTile(profileAddress),
            ),
            const SizedBox(height: 10),
          ],

          // Option 2: Custom address
          _addressOption(
            isSelected: _addressType == _AddressType.custom,
            onTap: () => setState(() => _addressType = _AddressType.custom),
            child: _customAddressTile(hasProfileAddress),
          ),

          // Custom address input (nếu chọn custom)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _addressType == _AddressType.custom
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Text field
                      TextField(
                        controller: _customAddressCtrl,
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        style: const TextStyle(
                            fontSize: 14,
                            color: _textDark,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText:
                              'VD: 123 Nguyễn Huệ, Phường Bến Nghé, Q.1, TP.HCM',
                          hintStyle: const TextStyle(
                              color: _textMuted, fontSize: 13),
                          prefixIcon: const Icon(
                              Icons.edit_location_alt_outlined,
                              size: 20,
                              color: _textMuted),
                          filled: true,
                          fillColor: const Color(0xFFFFF8F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: _orange, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),

                      // Save to profile checkbox
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => setState(
                            () => _saveAddressToProfile = !_saveAddressToProfile),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _saveAddressToProfile,
                                  onChanged: (v) => setState(
                                      () => _saveAddressToProfile = v!),
                                  activeColor: _orange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(4)),
                                  side: const BorderSide(
                                      color: Color(0xFFCCCCCC)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Lưu địa chỉ này vào hồ sơ của tôi',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _textDark,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _addressOption({
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFF3E8)
              : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _orange : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _orange : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: isSelected ? _orange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _profileAddressTile(String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined, size: 12, color: Color(0xFF22C55E)),
                  SizedBox(width: 4),
                  Text(
                    'Địa chỉ của tôi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          address,
          style: const TextStyle(
            fontSize: 13,
            color: _textDark,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _customAddressTile(bool hasProfileAddress) {
    return Row(
      children: [
        const Icon(Icons.add_location_alt_outlined, size: 18, color: _orange),
        const SizedBox(width: 8),
        Text(
          hasProfileAddress
              ? 'Giao đến địa chỉ khác'
              : 'Nhập địa chỉ giao hàng',
          style: const TextStyle(
            fontSize: 13,
            color: _textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Payment section ──────────────────────────────────────
  Widget _buildPaymentSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment_outlined,
                    size: 18, color: Color(0xFF5C6BC0)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Phương thức thanh toán',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _paymentOption(0, Icons.money_outlined, 'Tiền mặt',
              'Thanh toán khi nhận hàng', const Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          _paymentOption(1, Icons.account_balance_wallet_outlined, 'Ví điện tử',
              'MoMo / ZaloPay / VNPay', const Color(0xFFAB47BC)),
        ],
      ),
    );
  }

  Widget _paymentOption(int value, IconData icon, String title, String subtitle,
      Color iconColor) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E8) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _orange : const Color(0xFFEEEEEE),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _orange : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: selected ? _orange : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Order summary ────────────────────────────────────────
  Widget _buildOrderSummary(
      CartProvider cart, double subtotal, double deliveryFee, double total) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 18, color: Color(0xFFFF8F00)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tóm tắt đơn hàng',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items
          ...cart.items.values.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _textDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.food.name,
                        style: const TextStyle(
                            fontSize: 13,
                            color: _textDark,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${_formatPrice(item.totalPrice)}đ',
                      style: const TextStyle(
                          fontSize: 13,
                          color: _textDark,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 12),

          // Subtotal
          _summaryRow(
              'Tạm tính', '${_formatPrice(subtotal)}đ', isTotal: false),
          const SizedBox(height: 6),
          _summaryRow(
              'Phí giao hàng', '${_formatPrice(deliveryFee)}đ',
              isTotal: false),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 12),

          // Total
          _summaryRow('Tổng cộng', '${_formatPrice(total)}đ', isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            color: isTotal ? _textDark : _textMuted,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            color: isTotal ? _orange : _textDark,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Place order button ───────────────────────────────────
  Widget _buildPlaceOrderButton(CartProvider cart, double total) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPlacing ? null : () => _placeOrder(cart, total),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          disabledBackgroundColor: _orange.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isPlacing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Đặt hàng — ${_formatPrice(total)}đ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Section card wrapper ─────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}