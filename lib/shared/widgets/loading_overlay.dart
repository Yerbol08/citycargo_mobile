import 'package:flutter/material.dart';
import '../../app/theme.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay(
      {super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x80FFFFFF),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ),
      ],
    );
  }
}
