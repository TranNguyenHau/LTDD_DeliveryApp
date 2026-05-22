// lib/screens/admin/admin_account_screen.dart
// Màn hình quản lý tài khoản (Admin)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_app/models/account.dart';
import 'package:food_app/providers/account_provider.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  // ─── Palette (đồng bộ với AdminScreen) ─────────────────────
  static const _bg       = Color(0xFF0F172A);
  static const _surface  = Color(0xFF1E293B);
  static const _card     = Color(0xFF1A2744);
  static const _accent   = Color(0xFF3B82F6);
  static const _accentEnd= Color(0xFF6366F1);
  static const _danger   = Color(0xFFEF4444);
  static const _success  = Color(0xFF10B981);
  static const _warning  = Color(0xFFF59E0B);
  static const _text     = Colors.white;
  static const _textMuted= Color(0xFF94A3B8);
  static const _border   = Color(0xFF2D3F5C);

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all' | 'admin' | 'customer'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Hiển thị dialog xác nhận đổi role ─────────────────────
  void _showChangeRoleDialog(Account account) {
    final newRole = account.isAdmin ? 'customer' : 'admin';
    final newLabel = account.isAdmin ? 'Người dùng' : 'Admin';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => _ConfirmDialog(
        icon: Icons.manage_accounts_rounded,
        iconColor: _warning,
        title: 'Đổi quyền tài khoản?',
        message:
            'Chuyển "@${account.username}" thành $newLabel.\nHành động này có thể thay đổi quyền truy cập.',
        confirmLabel: 'Xác nhận',
        confirmColor: _warning,
        onConfirm: () async {
          final err = await context
              .read<AccountProvider>()
              .changeRole(account.id, newRole);
          if (!mounted) return;
          if (err != null) _showError(err);
        },
      ),
    );
  }

  // ─── Hiển thị dialog xác nhận xóa ──────────────────────────
  void _showDeleteDialog(Account account) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => _ConfirmDialog(
        icon: Icons.delete_forever_rounded,
        iconColor: _danger,
        title: 'Xóa tài khoản?',
        message:
            'Bạn có chắc muốn xóa "@${account.username}"?\nHành động này không thể hoàn tác.',
        confirmLabel: 'Xóa',
        confirmColor: _danger,
        onConfirm: () async {
          final err = await context
              .read<AccountProvider>()
              .deleteAccount(account.id);
          if (!mounted) return;
          if (err != null) _showError(err);
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _danger),
    );
  }

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final filtered = _applyFilters(provider.search(_searchQuery));

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(provider),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              _buildRoleFilter(provider),
              _buildStatsRow(provider),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: _accent))
                    : provider.errorMessage != null
                        ? _buildError(provider.errorMessage!)
                        : filtered.isEmpty
                            ? _buildEmpty()
                            : _buildList(filtered),
              ),
            ],
          ),
          if (provider.isSaving)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(color: _accent),
              ),
            ),
        ],
      ),
    );
  }

  List<Account> _applyFilters(List<Account> accounts) {
    if (_roleFilter == 'all') return accounts;
    return accounts.where((a) => a.role == _roleFilter).toList();
  }

  // ─── AppBar ─────────────────────────────────────────────────
  AppBar _buildAppBar(AccountProvider provider) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Quản lý tài khoản',
        style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: Text(
            '${provider.totalCount} tài khoản',
            style: const TextStyle(
                color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─── Search bar ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _text, fontSize: 14),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Tìm theo username, email...',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _textMuted, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Role filter chips ───────────────────────────────────────
  Widget _buildRoleFilter(AccountProvider provider) {
    final filters = [
      ('all', 'Tất cả', provider.totalCount),
      ('admin', 'Admin', provider.adminCount),
      ('customer', 'Người dùng', provider.userCount),
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final (value, label, count) = f;
          final selected = _roleFilter == value;
          return GestureDetector(
            onTap: () => setState(() => _roleFilter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [_accent, _accentEnd])
                    : null,
                color: selected ? null : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.transparent : _border,
                ),
              ),
              child: Text(
                '$label ($count)',
                style: TextStyle(
                  color: selected ? Colors.white : _textMuted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Stats row ───────────────────────────────────────────────
  Widget _buildStatsRow(AccountProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.people_rounded,
            label: 'Tổng',
            value: provider.totalCount,
            color: _accent,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin',
            value: provider.adminCount,
            color: _warning,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.person_rounded,
            label: 'User',
            value: provider.userCount,
            color: _success,
          ),
        ],
      ),
    );
  }

  // ─── Account list ────────────────────────────────────────────
  Widget _buildList(List<Account> accounts) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        return _AccountCard(
          account: accounts[index],
          onChangeRole: () => _showChangeRoleDialog(accounts[index]),
          onDelete: () => _showDeleteDialog(accounts[index]),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_accounts_rounded,
              size: 72, color: _textMuted.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy tài khoản',
            style: TextStyle(color: _textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: _danger),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onChangeRole;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onChangeRole,
    required this.onDelete,
  });

  static const _surface  = Color(0xFF1A2744);
  static const _border   = Color(0xFF2D3F5C);
  static const _accent   = Color(0xFF3B82F6);
  static const _accentEnd= Color(0xFF6366F1);
  static const _danger   = Color(0xFFEF4444);
  static const _success  = Color(0xFF10B981);
  static const _warning  = Color(0xFFF59E0B);
  static const _text     = Colors.white;
  static const _textMuted= Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final isAdmin = account.isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAdmin
              ? _warning.withOpacity(0.35)
              : _border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAdmin
                      ? [_warning, const Color(0xFFD97706)]
                      : [_accent, _accentEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  account.username.isNotEmpty
                      ? account.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '@${account.username}',
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(isAdmin: isAdmin),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.email,
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Column(
              children: [
                _SmallBtn(
                  icon: Icons.swap_horiz_rounded,
                  color: _warning,
                  tooltip: isAdmin ? 'Hạ quyền User' : 'Nâng quyền Admin',
                  onTap: onChangeRole,
                ),
                const SizedBox(height: 8),
                _SmallBtn(
                  icon: Icons.delete_rounded,
                  color: _danger,
                  tooltip: 'Xóa tài khoản',
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final bool isAdmin;
  const _RoleBadge({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? const Color(0xFFF59E0B).withOpacity(0.15)
            : const Color(0xFF10B981).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? const Color(0xFFF59E0B).withOpacity(0.4)
              : const Color(0xFF10B981).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
            size: 11,
            color: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 3),
          Text(
            isAdmin ? 'Admin' : 'User',
            style: TextStyle(
              color: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small Action Button ──────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  static const _surface = Color(0xFF1A2744);
  static const _border  = Color(0xFF2D3F5C);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm Dialog (dùng chung) ──────────────────────────────
class _ConfirmDialog extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final Future<void> Function() onConfirm;

  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  static const _surface  = Color(0xFF1E293B);
  static const _border   = Color(0xFF2D3F5C);
  static const _textMuted= Color(0xFF94A3B8);
  static const _text     = Colors.white;

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                color: widget.iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                  color: _text, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _border),
                      foregroundColor: _textMuted,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Hủy',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            await widget.onConfirm();
                            if (mounted) Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            widget.confirmLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}