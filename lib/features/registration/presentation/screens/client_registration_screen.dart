import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../../../../app/theme.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../domain/models/registration_model.dart';
import '../providers/registration_provider.dart';

class ClientRegistrationScreen extends ConsumerStatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  ConsumerState<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState
    extends ConsumerState<ClientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+7');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _role = 'sender';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(registrationProvider.notifier).registerClient(
            ClientRegistrationModel(
              fullName: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              role: _role,
            ),
          );
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'PHONE_EXISTS') {
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.phoneExistsTitle),
            content: Text(l10n.phoneExistsContent),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel)),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  child: Text(l10n.loginButton)),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.userMessage),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(registrationProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/register');
            }
          },
        ),
        title: Text(l10n.registration),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.horizontalPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                  controller: _nameCtrl,
                  label: l10n.fullNameLabel,
                  validator: (v) => Validators.required(v, l10n.nameLabel)),
              const SizedBox(height: 16),
              AppInput(
                  controller: _phoneCtrl,
                  label: l10n.phoneLabel,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone),
              const SizedBox(height: 16),
              AppInput(
                  controller: _emailCtrl,
                  label: l10n.emailOptionalLabel,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email),
              const SizedBox(height: 16),
              AppInput(
                  controller: _passwordCtrl,
                  label: l10n.passwordLabel,
                  obscureText: _obscure,
                  validator: Validators.password,
                  suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 16),
              AppInput(
                  controller: _confirmCtrl,
                  label: l10n.confirmPasswordLabel,
                  obscureText: _obscure,
                  validator: (v) =>
                      Validators.passwordConfirm(v, _passwordCtrl.text)),
              const SizedBox(height: 16),
              Text(l10n.roleLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              RadioGroup<String>(
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v!),
                child: Column(children: [
                  RadioListTile<String>(
                      value: 'sender', title: Text(l10n.sender)),
                  RadioListTile<String>(
                      value: 'recipient', title: Text(l10n.recipient)),
                ]),
              ),
              const SizedBox(height: 24),
              AppButton(
                  label: l10n.registerButton,
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
