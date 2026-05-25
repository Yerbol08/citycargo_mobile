import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';

class CourierPendingScreen extends StatelessWidget {
  const CourierPendingScreen({super.key});

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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                    color: AppColors.courierLight, shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 64, color: AppColors.courier),
              ),
              const SizedBox(height: 32),
              const Text('Заявка на рассмотрении',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              const Text(
                'Мы проверяем ваши данные. Обычно это занимает 1-2 рабочих дня. Мы уведомим вас о результате.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              AppButton(
                label: 'Войти с другим аккаунтом',
                onPressed: () => context.go('/login'),
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
