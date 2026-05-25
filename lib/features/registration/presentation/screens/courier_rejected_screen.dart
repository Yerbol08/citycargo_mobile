import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';

class CourierRejectedScreen extends StatelessWidget {
  final String? reason;
  const CourierRejectedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cancel_outlined,
                  size: 80, color: AppColors.danger),
              const SizedBox(height: 32),
              const Text('Заявка отклонена',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Text(
                reason ??
                    'К сожалению, ваша заявка была отклонена. Вы можете подать её повторно.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              AppButton(
                  label: 'Подать заявку снова',
                  onPressed: () => context.go('/register/courier')),
              const SizedBox(height: 12),
              AppButton(
                  label: 'На экран входа',
                  onPressed: () => context.go('/login'),
                  outlined: true),
            ],
          ),
        ),
      ),
    );
  }
}
