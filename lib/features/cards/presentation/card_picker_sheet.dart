import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/wallet_card.dart';

/// Account picker used by the new-expense screen and the transaction editor.
Future<WalletCard?> showCardPickerSheet(
  BuildContext context, {
  required List<WalletCard> cards,
  String? selectedId,
}) {
  final palette = AppThemeColors.of(context);
  final ordered = List<WalletCard>.from(cards)
    ..sort((a, b) {
      if (a.isPrimary == b.isPrimary) return 0;
      return a.isPrimary ? -1 : 1;
    });

  return showModalBottomSheet<WalletCard>(
    context: context,
    backgroundColor: palette.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select account',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              for (final c in ordered)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: c.startColor.withValues(alpha: 0.25),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: c.startColor,
                    ),
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    [
                      if (c.issuerLabel.isNotEmpty) c.issuerLabel,
                      '•••• ${c.lastFour}',
                      if (c.isPrimary) 'Primary',
                    ].join(' · '),
                  ),
                  trailing: selectedId == c.id
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, c),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
