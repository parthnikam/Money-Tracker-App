import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/transaction.dart';

/// Editable detail view for a transaction (title + notes).
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _dirty = false;
  String? _loadedId;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _hydrate(Transaction tx) {
    if (_loadedId == tx.id && _initialized) return;
    _titleCtrl.text = tx.title;
    _noteCtrl.text = tx.note ?? '';
    _loadedId = tx.id;
    _initialized = true;
    _dirty = false;
  }

  Future<void> _save(Transaction original) async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final noteRaw = _noteCtrl.text.trim();

    setState(() => _saving = true);
    final updated = original.copyWith(
      title: title,
      note: noteRaw.isEmpty ? null : noteRaw,
      clearNote: noteRaw.isEmpty,
    );

    await ref.read(transactionRepositoryProvider).update(updated);

    if (mounted) {
      setState(() {
        _saving = false;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved')),
      );
    }
  }

  Future<void> _confirmDelete(Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeColors.of(ctx).surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete transaction?'),
        content: Text(
          'Remove “${tx.title}”? This will reverse the amount on the linked wallet.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final txRepo = ref.read(transactionRepositoryProvider);
    final cardRepo = ref.read(cardRepositoryProvider);

    final cardList = await cardRepo.getAll();
    final card = cardList.where((c) => c.id == tx.cardId).firstOrNull;
    if (card != null) {
      final delta = tx.isIncome ? -tx.amount : tx.amount;
      await cardRepo.update(card.copyWith(balance: card.balance + delta));
    }
    await txRepo.delete(tx.id);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final cards = ref.watch(cardsProvider);
    final palette = AppThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      final list = transactions.valueOrNull;
                      final tx = list
                          ?.where((t) => t.id == widget.transactionId)
                          .firstOrNull;
                      if (tx != null) _save(tx);
                    },
              child: const Text('Save'),
            ),
        ],
      ),
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final match = list.where((t) => t.id == widget.transactionId);

          if (match.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: palette.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'Transaction not found',
                    style: TextStyle(color: palette.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          final tx = match.first;
          _hydrate(tx);

          final cats = categories.valueOrNull ?? [];
          final cardList = cards.valueOrNull ?? [];
          final cat = cats.where((c) => c.id == tx.categoryId).firstOrNull;
          final wallet = cardList.where((c) => c.id == tx.cardId).firstOrNull;

          final isExpense = tx.isExpense;
          final amountColor = isExpense
              ? AppColors.expenseOf(context)
              : AppColors.incomeOf(context);
          final typeLabel = isExpense ? 'Expense' : 'Income';
          final dateStr = DateFormat('EEEE, MMM d, yyyy').format(tx.date);

          final bottomInset = MediaQuery.paddingOf(context).bottom;
          return Form(
            key: _formKey,
            child: ListView(
              // Extra space so Delete clears the home indicator / system nav.
              padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + bottomInset),
              children: [
                // Amount summary (read-only)
                GlassCard(
                  depth: GlassDepth.outset,
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          cat?.icon ?? Icons.receipt_long_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormatter.formatSigned(
                          tx.amount,
                          isExpense: isExpense,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Editable title
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (!_dirty) setState(() => _dirty = true);
                  },
                  decoration: const InputDecoration(
                    hintText: 'What was this for?',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 18),

                // Editable notes
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (!_dirty) setState(() => _dirty = true);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Add notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Read-only meta
                GlassCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: cat?.name ?? 'Unknown',
                        valueColor: AppColors.primary,
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Card / wallet',
                        value: wallet?.name ?? 'Unknown',
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: dateStr,
                      ),
                      if (tx.paymentMethod != null &&
                          tx.paymentMethod!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Payment method',
                          value: tx.paymentMethod!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Save changes',
                  isLoading: _saving,
                  onPressed: _dirty && !_saving ? () => _save(tx) : null,
                ),
                const SizedBox(height: 12),
                GlassButton(
                  variant: GlassButtonVariant.destructive,
                  icon: Icons.delete_outline,
                  label: 'Delete transaction',
                  onPressed: _saving ? null : () => _confirmDelete(tx),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: palette.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: valueColor ?? palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
