import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../domain/models/registration_model.dart';
import '../providers/registration_provider.dart';

class CourierRegistrationScreen extends ConsumerStatefulWidget {
  const CourierRegistrationScreen({super.key});

  @override
  ConsumerState<CourierRegistrationScreen> createState() =>
      _CourierRegistrationScreenState();
}

class _CourierRegistrationScreenState
    extends ConsumerState<CourierRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+7');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _vehicleNumCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String _vehicleType = 'car';
  bool _obscure = true;

  final _vehicleTypes = ['car', 'motorcycle', 'bicycle', 'foot'];
  final _vehicleLabels = ['Автомобиль', 'Мотоцикл', 'Велосипед', 'Пешком'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _vehicleNumCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(registrationProvider.notifier).registerCourier(
            CourierRegistrationModel(
              fullName: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              vehicleType: _vehicleType,
              vehicleNumber: _vehicleNumCtrl.text.trim(),
              comment: _commentCtrl.text.trim(),
            ),
          );
      if (!mounted) return;
      context.go('/courier/pending');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.userMessage), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registrationProvider).isLoading;
    final needsVehicleNum =
        _vehicleType == 'car' || _vehicleType == 'motorcycle';
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
        title: const Text('Регистрация'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
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
                  label: 'Полное имя',
                  validator: (v) => Validators.required(v, 'Имя')),
              const SizedBox(height: 16),
              AppInput(
                  controller: _phoneCtrl,
                  label: 'Телефон',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone),
              const SizedBox(height: 16),
              AppInput(
                  controller: _emailCtrl,
                  label: 'Email (необязательно)',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email),
              const SizedBox(height: 16),
              AppInput(
                  controller: _passwordCtrl,
                  label: 'Пароль',
                  obscureText: _obscure,
                  validator: Validators.password,
                  suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 16),
              AppInput(
                  controller: _confirmCtrl,
                  label: 'Подтвердите пароль',
                  obscureText: _obscure,
                  validator: (v) =>
                      Validators.passwordConfirm(v, _passwordCtrl.text)),
              const SizedBox(height: 16),
              const Text('Тип транспорта',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(
                    _vehicleTypes.length,
                    (i) => ChoiceChip(
                          label: Text(_vehicleLabels[i]),
                          selected: _vehicleType == _vehicleTypes[i],
                          onSelected: (_) =>
                              setState(() => _vehicleType = _vehicleTypes[i]),
                          selectedColor: AppColors.courierLight,
                        )),
              ),
              if (needsVehicleNum) ...[
                const SizedBox(height: 16),
                AppInput(
                    controller: _vehicleNumCtrl,
                    label: 'Номер транспортного средства',
                    validator: needsVehicleNum
                        ? (v) => Validators.required(v, 'Номер ТС')
                        : null),
              ],
              const SizedBox(height: 16),
              AppInput(
                  controller: _commentCtrl,
                  label: 'Комментарий (необязательно)',
                  maxLines: 3),
              const SizedBox(height: 24),
              AppButton(
                  label: 'Подать заявку',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
