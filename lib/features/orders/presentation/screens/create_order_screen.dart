import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import 'package:citycargo_mobile/gen_l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../domain/models/address_result.dart';
import '../../domain/models/create_order_params.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderPhoneCtrl = TextEditingController(text: '+7');
  final _recipientPhoneCtrl = TextEditingController(text: '+7');
  final _senderAddressCtrl = TextEditingController();
  final _recipientAddressCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  AddressResult? _senderAddress;
  AddressResult? _recipientAddress;
  int _parcelCount = 1;

  @override
  void initState() {
    super.initState();
    _senderPhoneCtrl.addListener(() => _normalizePhone(_senderPhoneCtrl));
    _recipientPhoneCtrl.addListener(() => _normalizePhone(_recipientPhoneCtrl));
  }

  @override
  void dispose() {
    _senderPhoneCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _senderAddressCtrl.dispose();
    _recipientAddressCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAddress({required bool isSender}) async {
    final result = await context.push<AddressResult>('/orders/address-picker');
    if (result == null || !mounted) return;
    setState(() {
      if (isSender) {
        _senderAddress = result;
        _senderAddressCtrl.text = result.address;
      } else {
        _recipientAddress = result;
        _recipientAddressCtrl.text = result.address;
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  AddressResult? _validatedAddress({
    required TextEditingController controller,
    required AddressResult? selectedAddress,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final typedAddress = controller.text.trim();
    if (typedAddress.isEmpty) {
      _showError(l10n.enterAddress(label));
      return null;
    }

    if (selectedAddress == null ||
        !selectedAddress.hasCoordinates ||
        selectedAddress.address != typedAddress) {
      _showError(l10n.selectOnMapToSave(label));
      return null;
    }

    return selectedAddress;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final senderAddress = _validatedAddress(
      controller: _senderAddressCtrl,
      selectedAddress: _senderAddress,
      label: l10n.senderAddressLabel.toLowerCase(),
    );
    final recipientAddress = _validatedAddress(
      controller: _recipientAddressCtrl,
      selectedAddress: _recipientAddress,
      label: l10n.recipientAddressLabel.toLowerCase(),
    );
    if (senderAddress == null || recipientAddress == null) return;

    final params = CreateOrderParams(
      senderPhone: _senderPhoneCtrl.text.trim(),
      senderAddress: senderAddress.address,
      senderLat: senderAddress.lat,
      senderLng: senderAddress.lng,
      recipientPhone: _recipientPhoneCtrl.text.trim(),
      recipientAddress: recipientAddress.address,
      recipientLat: recipientAddress.lat,
      recipientLng: recipientAddress.lng,
      parcelCount: _parcelCount,
      comment: _commentCtrl.text.trim(),
    );

    context.push('/orders/preview', extra: params);
  }

  void _normalizePhone(TextEditingController controller) {
    final raw = controller.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    var normalizedDigits = digits;
    if (normalizedDigits.startsWith('8')) {
      normalizedDigits = '7${normalizedDigits.substring(1)}';
    }
    if (!normalizedDigits.startsWith('7')) {
      normalizedDigits = '7$normalizedDigits';
    }
    if (normalizedDigits.length > 11) {
      normalizedDigits = normalizedDigits.substring(0, 11);
    }
    final normalized = '+$normalizedDigits';
    if (raw == normalized) return;
    controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  void _addCommentTag(String value) {
    final current = _commentCtrl.text.trim();
    final next = current.isEmpty ? value : '$current, $value';
    setState(() {
      _commentCtrl.text = next;
      _commentCtrl.selection = TextSelection.collapsed(offset: next.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit = _senderAddress?.hasCoordinates == true &&
        _recipientAddress?.hasCoordinates == true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newOrder)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _PricePreview(canSubmit: canSubmit),
                  const SizedBox(height: 12),
                  _FormSection(
                    title: l10n.sender,
                    icon: Icons.upload_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    children: [
                      AppInput(
                        controller: _senderPhoneCtrl,
                        label: l10n.senderPhone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 12),
                      _AddressInput(
                        controller: _senderAddressCtrl,
                        label: l10n.senderAddressLabel,
                        selectedAddress: _senderAddress,
                        onMapTap: () => _pickAddress(isSender: true),
                        onChanged: () => setState(() => _senderAddress = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FormSection(
                    title: l10n.recipient,
                    icon: Icons.download_rounded,
                    color: Theme.of(context).colorScheme.error,
                    children: [
                      AppInput(
                        controller: _recipientPhoneCtrl,
                        label: l10n.recipientPhone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 12),
                      _AddressInput(
                        controller: _recipientAddressCtrl,
                        label: l10n.recipientAddressLabel,
                        selectedAddress: _recipientAddress,
                        onMapTap: () => _pickAddress(isSender: false),
                        onChanged: () => setState(() => _recipientAddress = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FormSection(
                    title: l10n.parcel,
                    icon: Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    children: [
                      _ParcelCounter(
                        count: _parcelCount,
                        onDecrement: _parcelCount > 1
                            ? () => setState(() => _parcelCount--)
                            : null,
                        onIncrement: () => setState(() => _parcelCount++),
                      ),
                      const SizedBox(height: 12),
                      _QuickCommentChips(onSelected: _addCommentTag),
                      const SizedBox(height: 12),
                      AppInput(
                        controller: _commentCtrl,
                        label: l10n.commentLabel,
                        hint: l10n.commentHint,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppButton(
                  label: l10n.continueButton,
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricePreview extends StatelessWidget {
  final bool canSubmit;

  const _PricePreview({required this.canSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preliminaryPrice,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  l10n.priceNotice,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            canSubmit ? '1 500 ₸' : '--',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _AddressInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final AddressResult? selectedAddress;
  final VoidCallback onMapTap;
  final VoidCallback onChanged;

  const _AddressInput({
    required this.controller,
    required this.label,
    required this.selectedAddress,
    required this.onMapTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMapPoint = selectedAddress?.hasCoordinates == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          minLines: 1,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.enterAddress(label.toLowerCase());
            }
            if (!hasMapPoint) {
              return l10n.needToSelectOnMap;
            }
            return null;
          },
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: l10n.selectAddressHint,
            prefixIcon: Icon(
              hasMapPoint ? Icons.place : Icons.edit_location_alt_outlined,
              color: hasMapPoint ? theme.colorScheme.primary : theme.disabledColor,
            ),
            suffixIcon: IconButton(
              tooltip: l10n.map,
              icon: const Icon(Icons.map_outlined),
              color: theme.colorScheme.primary,
              onPressed: onMapTap,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(
              hasMapPoint ? Icons.check_circle : Icons.info_outline,
              size: 14,
              color: hasMapPoint
                  ? theme.colorScheme.secondary
                  : theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              hasMapPoint ? l10n.coordsSaved : l10n.needToSelectOnMap,
              style: TextStyle(
                color: hasMapPoint
                    ? theme.colorScheme.secondary
                    : theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onMapTap,
              icon: const Icon(Icons.map_outlined, size: 16),
              label: Text(l10n.map),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCommentChips extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _QuickCommentChips({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = [l10n.tagHome, l10n.tagOffice, l10n.tagWarehouse];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          ActionChip(
            label: Text(tag),
            avatar: const Icon(Icons.add, size: 16),
            onPressed: () => onSelected(tag),
          ),
      ],
    );
  }
}

class _ParcelCounter extends StatelessWidget {
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _ParcelCounter({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.parcelCountLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove),
                onPressed: onDecrement,
                color: onDecrement != null
                    ? theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary
                    : theme.disabledColor,
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add),
                onPressed: onIncrement,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
