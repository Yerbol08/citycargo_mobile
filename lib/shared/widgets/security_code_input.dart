import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';

enum CodeType { pickup, delivery }

class SecurityCodeInput extends StatefulWidget {
  final CodeType type;
  final Future<void> Function(String code) onSubmit;

  const SecurityCodeInput({
    super.key,
    required this.type,
    required this.onSubmit,
  });

  @override
  State<SecurityCodeInput> createState() => _SecurityCodeInputState();
}

class _SecurityCodeInputState extends State<SecurityCodeInput> {
  final List<String> _digits = List.filled(4, '');
  bool _hasError = false;
  bool _isSuccess = false;
  bool _isLoading = false;
  int _attempts = 0;
  DateTime? _blockedUntil;
  Timer? _blockTimer;

  @override
  void dispose() {
    _blockTimer?.cancel();
    super.dispose();
  }

  Color get _activeColor =>
      widget.type == CodeType.pickup ? AppColors.courier : AppColors.success;

  Color get _activeBgColor => widget.type == CodeType.pickup
      ? AppColors.courierLight
      : AppColors.successLight;

  bool get _isBlocked =>
      _blockedUntil != null && DateTime.now().isBefore(_blockedUntil!);

  bool get _isFull => _digits.every((d) => d.isNotEmpty);

  void _onDigit(String d) {
    if (_isBlocked || _isSuccess || _isLoading) return;
    final idx = _digits.indexWhere((x) => x.isEmpty);
    if (idx == -1) return;
    setState(() {
      _digits[idx] = d;
      _hasError = false;
    });
    if (_isFull) _submit();
  }

  void _onDelete() {
    if (_isBlocked || _isSuccess || _isLoading) return;
    final idx = _digits.lastIndexWhere((x) => x.isNotEmpty);
    if (idx == -1) return;
    setState(() => _digits[idx] = '');
  }

  Future<void> _submit() async {
    final code = _digits.join();
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(code);
      if (!mounted) return;
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      _attempts++;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });

      if (_attempts >= 5) {
        final until = DateTime.now().add(const Duration(minutes: 5));
        setState(() => _blockedUntil = until);
        _blockTimer?.cancel();
        _blockTimer = Timer(const Duration(minutes: 5), () {
          if (mounted) {
            setState(() {
              _blockedUntil = null;
              _attempts = 0;
            });
          }
        });
      }

      Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          for (var i = 0; i < 4; i++) {
            _digits[i] = '';
          }
          _hasError = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (_isBlocked)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              l10n.tooManyAttempts,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, height: 1.4),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (i) => _CodeCell(
              digit: _digits[i],
              hasError: _hasError,
              isSuccess: _isSuccess,
              activeColor: _activeColor,
              activeBgColor: _activeBgColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_hasError)
          Text(
            l10n.invalidCode,
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (_isSuccess)
          Text(
            l10n.codeAccepted,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (!_isSuccess && !_isBlocked)
          _Numpad(
            onDigit: _onDigit,
            onDelete: _onDelete,
            isLoading: _isLoading,
          ),
      ],
    );
  }
}

class _CodeCell extends StatelessWidget {
  final String digit;
  final bool hasError;
  final bool isSuccess;
  final Color activeColor;
  final Color activeBgColor;

  const _CodeCell({
    required this.digit,
    required this.hasError,
    required this.isSuccess,
    required this.activeColor,
    required this.activeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Theme.of(context).scaffoldBackgroundColor;
    Color border = Theme.of(context).dividerColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    if (hasError && digit.isNotEmpty) {
      bg = AppColors.dangerLight;
      border = AppColors.danger;
      textColor = AppColors.danger;
    } else if (isSuccess && digit.isNotEmpty) {
      bg = AppColors.successLight;
      border = AppColors.success;
      textColor = AppColors.success;
    } else if (digit.isNotEmpty) {
      bg = activeBgColor;
      border = activeColor;
      textColor = activeColor;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      alignment: Alignment.center,
      child: digit.isEmpty
          ? null
          : Text(
              digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final bool isLoading;

  const _Numpad({
    required this.onDigit,
    required this.onDelete,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        final isDelete = k == '⌫';
        return InkWell(
          onTap: isLoading ? null : () => isDelete ? onDelete() : onDigit(k),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Center(
            child: Text(
              k,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLoading 
                    ? Theme.of(context).disabledColor 
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
