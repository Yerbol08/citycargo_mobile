import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_role.dart';
import '../../../../app/theme.dart';
import '../providers/auth_provider.dart';

class AppRoleSelectScreen extends ConsumerWidget {
  const AppRoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final roles = auth.availableRoles.normalizedForApp;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            '\u0412\u044b\u0431\u043e\u0440 \u0440\u043e\u043b\u0438'),
        actions: [
          IconButton(
            tooltip: '\u0412\u044b\u0439\u0442\u0438',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '\u041a\u0430\u043a\u043e\u0439 \u043a\u0430\u0431\u0438\u043d\u0435\u0442 \u043e\u0442\u043a\u0440\u044b\u0442\u044c?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u0423 \u0432\u0430\u0441 \u043d\u0435\u0441\u043a\u043e\u043b\u044c\u043a\u043e \u0440\u043e\u043b\u0435\u0439. \u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435, \u0441 \u0447\u0435\u043c \u0440\u0430\u0431\u043e\u0442\u0430\u0435\u043c \u0441\u0435\u0439\u0447\u0430\u0441.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            for (final role in roles) ...[
              _RoleTile(role: role),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends ConsumerWidget {
  final AppRole role;

  const _RoleTile({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (role) {
      AppRole.courier => AppColors.courier,
      AppRole.operator => AppColors.primary,
      AppRole.moderator => AppColors.danger,
      _ => AppColors.primary,
    };

    final icon = switch (role) {
      AppRole.moderator => Icons.admin_panel_settings_outlined,
      AppRole.operator => Icons.support_agent_outlined,
      AppRole.courier => Icons.delivery_dining,
      _ => Icons.person_outline,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () async {
          await ref.read(authProvider.notifier).setActiveRole(role);
          if (context.mounted) context.go(role.shellPath);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  role.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
