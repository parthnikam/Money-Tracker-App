import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/wallet_card_widget.dart';
import '../../cards/domain/wallet_card.dart';
import 'delete_card.dart';
import '../../transactions/domain/category.dart';
import '../../transactions/domain/transaction.dart';

/// Wallet tab — spacing/placement aligned with `ui_design/wallet.png`.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  int _selectedIndex = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final cardsAsync = ref.watch(cardsProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (cards) {
            if (cards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No cards yet',
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      expand: false,
                      label: 'Add card',
                      onPressed: () => context.push('/cards/add'),
                    ),
                  ],
                ),
              );
            }

            final index = _selectedIndex.clamp(0, cards.length - 1);
            final selected = cards[index];

            final cardTx = (transactions.valueOrNull ?? [])
                .where((t) => t.cardId == selected.id)
                .where((t) {
                  if (_query.isEmpty) return true;
                  return t.title.toLowerCase().contains(_query.toLowerCase());
                })
                .toList();

            final cats = categories.valueOrNull ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.pagePadding,
                      16,
                      AppConstants.pagePadding,
                      0,
                    ),
                    child: Column(
                      children: [
                        // Title + edit / remove / add. Left-aligned so the
                        // actions stay tappable on a narrow phone.
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Wallet Details',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit card',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  context.push('/cards/edit/${selected.id}'),
                              icon: const Icon(Icons.edit_outlined),
                              color: palette.textSecondary,
                            ),
                            IconButton(
                              tooltip: 'Remove card',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                await confirmDeleteCard(context, ref, selected);
                              },
                              icon: const Icon(Icons.delete_outline),
                              color: AppColors.expenseOf(context),
                            ),
                            IconButton(
                              tooltip: 'Add card',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => context.push('/cards/add'),
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Large card — tap to edit
                        WalletCardWidget(
                          card: selected,
                          onTap: () =>
                              context.push('/cards/edit/${selected.id}'),
                        ),
                        const SizedBox(height: 18),

                        // Wallet dropdown (centered pill) — like design
                        _WalletDropdown(
                          cards: cards,
                          selected: selected,
                          onSelected: (c) {
                            final i = cards.indexWhere((x) => x.id == c.id);
                            if (i >= 0) setState(() => _selectedIndex = i);
                          },
                        ),
                        const SizedBox(height: 18),

                        // Search
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 20,
                                color: palette.textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => setState(() => _query = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search for any transaction',
                                    hintStyle: TextStyle(
                                      color: palette.textTertiary,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (cardTx.isEmpty)
                  // empty
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.pagePadding,
                        vertical: 24,
                      ),
                      child: Center(
                        child: Text(
                          'No transactions for this card',
                          style: TextStyle(color: palette.textTertiary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.pagePadding,
                    ),
                    sliver: SliverList.separated(
                      itemCount: cardTx.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final tx = cardTx[i];
                        final cat = cats
                            .where((c) => c.id == tx.categoryId)
                            .firstOrNull;
                        return _WalletTxRow(
                          transaction: tx,
                          category: cat,
                          onTap: () => context.push('/transactions/${tx.id}'),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pill dropdown under the card (design: "Entertainment wallet ▾").
class _WalletDropdown extends StatelessWidget {
  const _WalletDropdown({
    required this.cards,
    required this.selected,
    required this.onSelected,
  });

  final List<WalletCard> cards;
  final WalletCard selected;
  final ValueChanged<WalletCard> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);

    return PopupMenuButton<WalletCard>(
      onSelected: onSelected,
      color: palette.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => cards
          .map(
            (c) => PopupMenuItem(
              value: c,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [c.startColor, c.endColor],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.name),
                        if (c.issuerLabel.isNotEmpty)
                          Text(
                            c.issuerLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (c.id == selected.id)
                    const Icon(Icons.check, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more, size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Transaction row matching wallet design: icon · title/date · amount/method.
class _WalletTxRow extends StatelessWidget {
  const _WalletTxRow({required this.transaction, this.category, this.onTap});

  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final isExpense = transaction.isExpense;
    final amountColor = isExpense
        ? AppColors.expenseOf(context)
        : AppColors.incomeOf(context);
    final dateStr = DateFormat('MMMM d, y').format(transaction.date);
    final method = transaction.paymentMethod;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category?.icon ?? Icons.receipt_long_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: palette.textTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatSigned(
                    transaction.amount,
                    isExpense: isExpense,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: amountColor,
                  ),
                ),
                if (method != null && method.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    method.startsWith('Paid') ? method : 'Paid with $method',
                    style: TextStyle(fontSize: 11, color: palette.textTertiary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
