import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_cards.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(adminRepositoryProvider).getUsers();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openUser(Map<String, dynamic> user) async {
    final userId = _text(user, ['id', 'user_id']);
    try {
      final details =
          await ref.read(adminRepositoryProvider).getUserDetails(userId);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _UserDetailsSheet(
          userId: userId,
          data: details.isEmpty ? user : details,
          onSaved: _refresh,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0442\u043a\u0440\u044b\u0442\u044c \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final users = snap.data ?? const <Map<String, dynamic>>[];
        return AdminListScaffold(
          title:
              '\u041f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u0438',
          isLoading: snap.connectionState == ConnectionState.waiting,
          error: snap.hasError
              ? userErrorMessage(
                  snap.error!,
                  fallback: 'Не удалось загрузить пользователей',
                )
              : null,
          onRefresh: _refresh,
          children: [
            for (final user in users)
              AdminDataCard(
                title: _text(user, ['full_name', 'name', 'phone']),
                subtitle: _text(user, ['phone', 'email', 'id']),
                trailing: _roles(user),
                icon: Icons.person_outline,
                onTap: () => _openUser(user),
              ),
          ],
        );
      },
    );
  }

  String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '-';
  }

  String _roles(Map<String, dynamic> user) {
    final roles = user['roles'] ?? user['role_codes'] ?? user['role'];
    if (roles is List) return roles.map((e) => e.toString()).join(', ');
    return roles?.toString() ?? '';
  }
}

class _UserDetailsSheet extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic> data;
  final VoidCallback onSaved;

  const _UserDetailsSheet({
    required this.userId,
    required this.data,
    required this.onSaved,
  });

  @override
  ConsumerState<_UserDetailsSheet> createState() => _UserDetailsSheetState();
}

class _UserDetailsSheetState extends ConsumerState<_UserDetailsSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _rolesCtrl;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: _text(widget.data, ['full_name', 'name']));
    _phoneCtrl = TextEditingController(text: _text(widget.data, ['phone']));
    _emailCtrl = TextEditingController(text: _text(widget.data, ['email']));
    _rolesCtrl = TextEditingController(text: _roles(widget.data));
    _active = widget.data['is_active'] != false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _rolesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateUser(widget.userId, {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'is_active': _active,
        'role_codes': _rolesCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          const Text(
            '\u041a\u0430\u0440\u0442\u043e\u0447\u043a\u0430 \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '\u0418\u043c\u044f'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
                labelText: '\u0422\u0435\u043b\u0435\u0444\u043e\u043d'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rolesCtrl,
            decoration: const InputDecoration(
              labelText:
                  '\u0420\u043e\u043b\u0438 \u0447\u0435\u0440\u0435\u0437 \u0437\u0430\u043f\u044f\u0442\u0443\u044e',
            ),
          ),
          SwitchListTile(
            value: _active,
            onChanged: (value) => setState(() => _active = value),
            title: const Text('\u0410\u043a\u0442\u0438\u0432\u0435\u043d'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text(
              '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c',
            ),
          ),
        ],
      ),
    );
  }

  String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _roles(Map<String, dynamic> user) {
    final roles = user['roles'] ?? user['role_codes'] ?? user['role'];
    if (roles is List) return roles.map((e) => e.toString()).join(', ');
    return roles?.toString() ?? '';
  }
}
