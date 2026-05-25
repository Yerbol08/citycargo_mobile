import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/validators.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+7');
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(authProvider.notifier).login(
            _phoneCtrl.text.trim(),
            _passwordCtrl.text,
          );
      final user = ref.read(authProvider).user;
      if (!mounted || user == null) return;
      final activeRole = ref.read(authProvider).activeRole;
      context.go(activeRole?.shellPath ?? '/role-select');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.userMessage);
    } catch (_) {
      if (!mounted) return;
      _showError(l10n.loginFailed);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 56),
                const _AuthLogo(),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      AppInput(
                        controller: _phoneCtrl,
                        label: l10n.phoneLabel,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        prefix: const Icon(Icons.phone_outlined),
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: _passwordCtrl,
                        label: l10n.passwordLabel,
                        obscureText: _obscure,
                        validator: Validators.password,
                        prefix: const Icon(Icons.lock_outline),
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      if (authState.error != null) ...[
                        const SizedBox(height: 14),
                        _LoginError(message: authState.error!),
                      ],
                      const SizedBox(height: 22),
                      AppButton(
                        label: l10n.loginButton,
                        onPressed: authState.isLoading ? null : _submit,
                        isLoading: authState.isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    l10n.noAccountRegister,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.textPrimary, // Keeping dark as brand element
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.authSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  final String message;

  const _LoginError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
