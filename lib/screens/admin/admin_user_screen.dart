// lib/screens/admin/admin_user_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/firestore_collections.dart';

// ─── Merged model ────────────────────────────────────────────────────────────

class _MergedUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String role;
  final DateTime? createdAt;

  const _MergedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.createdAt,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  // Theme colors
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _card = Color(0xFF1A2744);
  static const _accent = Color(0xFF3B82F6);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFF2D3F5C);
  static const _green = Color(0xFF22C55E);

  final _db = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();

  // accounts map: uid → role
  Map<String, String> _accountRoles = {};
  bool _accountsLoaded = false;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    try {
      final snap = await _db.collection(FirestoreCollections.accounts).get();
      final map = <String, String>{};
      for (final doc in snap.docs) {
        map[doc.id] = (doc.data()['role'] as String?) ?? 'user';
      }
      if (!mounted) return;
      setState(() {
        _accountRoles = map;
        _accountsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _accountsLoaded = true);
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<_MergedUser> _merge(List<QueryDocumentSnapshot> userDocs) {
    final list = <_MergedUser>[];
    for (final doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = _accountRoles[doc.id] ?? 'user';
      if (role == 'admin') continue; // hide admins
      list.add(_MergedUser(
        id: doc.id,
        fullName: data['fullName'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        address: data['address'] as String? ?? '',
        role: role,
        createdAt: _parseDateTime(data['createdAt']),
      ));
    }
    // sort newest first
    list.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return list;
  }

  List<_MergedUser> _applySearch(List<_MergedUser> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((u) {
      return u.fullName.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // ─── Bottom sheet: user detail ─────────────────────────────────────────────

  void _showDetail(_MergedUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _UserDetailSheet(user: user, db: _db, card: _card, accent: _accent, text: _text, textMuted: _textMuted, border: _border, green: _green),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Quản lý người dùng', style: TextStyle(color: _text, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection(FirestoreCollections.users).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting || !_accountsLoaded) {
            return const Center(child: CircularProgressIndicator(color: _accent));
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}', style: const TextStyle(color: _text)));
          }

          final allUsers = _merge(snap.data?.docs ?? []);
          final filtered = _applySearch(allUsers);

          // Stats
          final today = DateTime.now();
          final newToday = allUsers.where((u) {
            if (u.createdAt == null) return false;
            final d = u.createdAt!;
            return d.year == today.year && d.month == today.month && d.day == today.day;
          }).length;
          final hasPhone = allUsers.where((u) => u.phone.isNotEmpty).length;

          return RefreshIndicator(
            color: _accent,
            onRefresh: _fetchAccounts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Stats ──
                _buildStats(allUsers.length, newToday, hasPhone),
                const SizedBox(height: 16),

                // ── Search ──
                _buildSearchBar(),
                const SizedBox(height: 16),

                // ── List ──
                if (filtered.isEmpty)
                  _buildEmpty()
                else
                  ...filtered.map((u) => _buildUserCard(u)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStats(int total, int newToday, int hasPhone) {
    return Row(
      children: [
        _statCard('👥', 'Tổng KH', total.toString()),
        const SizedBox(width: 10),
        _statCard('📅', 'Mới hôm nay', newToday.toString()),
        const SizedBox(width: 10),
        _statCard('📱', 'Có SĐT', hasPhone.toString()),
      ],
    );
  }

  Widget _statCard(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: _textMuted, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: _text),
      decoration: InputDecoration(
        hintText: 'Tìm theo tên hoặc email...',
        hintStyle: const TextStyle(color: _textMuted),
        prefixIcon: const Icon(Icons.search, color: _textMuted),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, color: _textMuted),
                onPressed: () => _searchCtrl.clear(),
              )
            : null,
        filled: true,
        fillColor: _surface,
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
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  // ─── User card ─────────────────────────────────────────────────────────────

  Widget _buildUserCard(_MergedUser user) {
    final initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
    final joinedStr = user.createdAt != null
        ? 'Tham gia: ${DateFormat('dd/MM/yyyy').format(user.createdAt!)}'
        : 'Chưa rõ ngày tham gia';

    return GestureDetector(
      onTap: () => _showDetail(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _accent,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName : 'Chưa cập nhật tên',
                          style: const TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withOpacity(0.4)),
                        ),
                        child: const Text('Khách hàng', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(user.email, style: const TextStyle(color: _textMuted, fontSize: 13), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  user.phone.isNotEmpty
                      ? Text(user.phone, style: const TextStyle(color: _textMuted, fontSize: 13))
                      : const Text('Chưa cập nhật SĐT', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 3),
                  Text(joinedStr, style: const TextStyle(color: _textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textMuted),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.people_outline, color: _textMuted, size: 64),
            SizedBox(height: 16),
            Text('Chưa có khách hàng nào', style: TextStyle(color: _textMuted, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ─── User Detail Bottom Sheet ─────────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  final _MergedUser user;
  final FirebaseFirestore db;
  final Color card, accent, text, textMuted, border, green;

  const _UserDetailSheet({
    required this.user,
    required this.db,
    required this.card,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.green,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  int _orderCount = 0;
  double _totalSpent = 0;
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrderStats();
  }

  Future<void> _loadOrderStats() async {
    try {
      final snap = await widget.db
          .collection(FirestoreCollections.orders)
          .where('userId', isEqualTo: widget.user.id)
          .where('status', isEqualTo: 'delivered')
          .get();
      double total = 0;
      for (final doc in snap.docs) {
        total += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
      }
      if (!mounted) return;
      setState(() {
        _orderCount = snap.docs.length;
        _totalSpent = total;
        _loadingOrders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final fmt = NumberFormat.decimalPattern();
    final joinedStr = u.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(u.createdAt!)
        : '---';

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: widget.textMuted, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Avatar + name
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: widget.accent,
                child: Text(
                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName.isNotEmpty ? u.fullName : 'Chưa cập nhật', style: TextStyle(color: widget.text, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(u.email, style: TextStyle(color: widget.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Details
          _detailRow(Icons.phone, 'SĐT', u.phone.isNotEmpty ? u.phone : 'Chưa cập nhật'),
          _detailRow(Icons.location_on_outlined, 'Địa chỉ', u.address.isNotEmpty ? u.address : 'Chưa cập nhật'),
          _detailRow(Icons.calendar_today_outlined, 'Tham gia', joinedStr),

          const SizedBox(height: 12),
          Divider(color: widget.border),
          const SizedBox(height: 12),

          // Order stats
          if (_loadingOrders)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(child: _statBox('Đơn hoàn thành', _orderCount.toString())),
                const SizedBox(width: 12),
                Expanded(child: _statBox('Tổng chi tiêu', '${fmt.format(_totalSpent)}đ')),
              ],
            ),

          const SizedBox(height: 20),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: widget.textMuted, size: 18),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: widget.textMuted, fontSize: 14)),
          Expanded(child: Text(value, style: TextStyle(color: widget.text, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: widget.text, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: widget.textMuted, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
