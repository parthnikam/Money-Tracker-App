import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/transactions/domain/category.dart';
import '../../features/transactions/domain/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
    this.onDismiss,
    this.showCategoryIcon = true,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  /// When false, hides the colored category circle (used on Stats).
  final bool showCategoryIcon;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final isExpense = transaction.isExpense;
    final amountColor =
        isExpense ? AppColors.expenseOf(context) : AppColors.incomeOf(context);
    final dateStr = _dateFmt.format(transaction.date);

    // Lightweight row — avoid ListTile overhead in long scrolling lists.
    final tile = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              if (showCategoryIcon) ...[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category?.icon ?? Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        dateStr,
                        if (transaction.paymentMethod != null)
                          transaction.paymentMethod!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.formatSigned(
                  transaction.amount,
                  isExpense: isExpense,
                ),
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onDismiss == null) return tile;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expenseOf(context).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.expenseOf(context)),
      ),
      onDismissed: (_) => onDismiss!(),
      child: tile,
    );
  }
}
