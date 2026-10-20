import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/wallet_card.dart';

/// Asks, then deletes [card]. Past transactions are left in history.
/// Returns true when the card was removed.
Future<bool> confirmDeleteCard(
  BuildContext context,
  WidgetRef ref,
  WalletCard card,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppThemeColors.of(ctx).surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Remove card?'),
      content: Text(
        'Remove “${card.name}”? This wallet and its balance go away. '
        'Transactions already recorded stay in your history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.expenseOf(ctx),
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  await ref.read(cardRepositoryProvider).delete(card.id);
  return true;
}
