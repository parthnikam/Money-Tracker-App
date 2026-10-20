import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../cards/domain/wallet_card.dart';
import '../../cards/presentation/card_picker_sheet.dart';
import '../domain/category.dart';
import '../domain/transaction.dart';
import 'category_picker_sheet.dart';

/// Compact editor for one transaction. Plain rows, no glass surfaces.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _loadedId;
  bool _saving = false;
  bool _dirty = false;
  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  String? _cardId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _load(Transaction tx) {
    if (_loadedId == tx.id) return;
    _loadedId = tx.id;
    _titleCtrl.text = tx.title;
    _noteCtrl.text = tx.note ?? '';
    _amountCtrl.text = tx.amount == tx.amount.roundToDouble()
        ? tx.amount.toStringAsFixed(0)
        : tx.amount.toStringAsFixed(2);
    _type = tx.type;
    _categoryId = tx.categoryId;
    _cardId = tx.cardId;
    _date = tx.date;
    _dirty = false;
  }

  void _markDirty() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  Future<void> _save(Transaction saved) async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final categoryId = _categoryId;
    final cardId = _cardId;
    if (title.isEmpty) {
      _toast('Title is required');
      return;
    }
    if (amount == null || amount <= 0) {
      _toast('Enter an amount');
      return;
    }
    if (categoryId == null) {
      _toast('Pick a category');
      return;
    }
    if (cardId == null) {
      _toast('Pick a card');
      return;
    }

    setState(() => _saving = true);
    final note = _noteCtrl.text.trim();
    final updated = saved.copyWith(
      title: title,
      amount: amount,
      type: _type,
      categoryId: categoryId,
      cardId: cardId,
      date: _date,
      note: note.isEmpty ? null : note,
      clearNote: note.isEmpty,
    );

    await _applyBalanceChange(saved, updated);
    await ref.read(transactionRepositoryProvider).update(updated);
    if (mounted) context.pop();
  }

  /// Reverse the saved effect, then apply the edited one.
  Future<void> _applyBalanceChange(Transaction before, Transaction after) async {
    final beforeDelta = before.balanceDelta;
    final afterDelta = after.balanceDelta;
    if (before.cardId == after.cardId && beforeDelta == afterDelta) return;

    final cardRepo = ref.read(cardRepositoryProvider);
    final cards = await cardRepo.getAll();
    final byId = {for (final c in cards) c.id: c};

    if (before.cardId == after.cardId) {
      final card = byId[before.cardId];
      if (card == null) return;
      await cardRepo.update(
        card.copyWith(balance: card.balance - beforeDelta + afterDelta),
      );
      return;
    }

    final oldCard = byId[before.cardId];
    if (oldCard != null) {
      await cardRepo.update(
        oldCard.copyWith(balance: oldCard.balance - beforeDelta),
      );
    }
    final newCard = byId[after.cardId];
    if (newCard != null) {
      await cardRepo.update(
        newCard.copyWith(balance: newCard.balance + afterDelta),
      );
    }
  }

  Future<void> _confirmDelete(Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeColors.of(ctx).surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete transaction?'),
        content: Text(
          'Remove “${tx.title}”? This reverses the amount on the linked wallet.',
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

    final cardRepo = ref.read(cardRepositoryProvider);
    final cards = await cardRepo.getAll();
    final card = cards.where((c) => c.id == tx.cardId).firstOrNull;
    if (card != null) {
      await cardRepo.update(
        card.copyWith(balance: card.balance - tx.balanceDelta),
      );
    }
    await ref.read(transactionRepositoryProvider).delete(tx.id);
    if (mounted) context.pop();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showCategoryPickerSheet(
      context,
      selectedId: _categoryId,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _categoryId = selected.id;
      _dirty = true;
    });
  }

  Future<void> _pickCard() async {
    final cards = ref.read(cardsProvider).valueOrNull ?? [];
    if (cards.isEmpty) {
      _toast('Add a card first');
      return;
    }
    final picked = await showCardPickerSheet(
      context,
      cards: cards,
      selectedId: _cardId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _cardId = picked.id;
      _dirty = true;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
      _dirty = true;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final list = ref.watch(transactionsProvider).valueOrNull;
    final tx = list?.where((t) => t.id == widget.transactionId).firstOrNull;
    if (tx != null) _load(tx);

    return Scaffold(
      appBar: AppBar(
        title: Text(_type == TransactionType.expense ? 'Expense' : 'Income'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: tx == null || !_dirty || _saving ? null : () => _save(tx),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: tx == null
          ? Center(
              child: list == null
                  ? const CircularProgressIndicator()
                  : Text(
                      'Transaction not found',
                      style: TextStyle(color: palette.textSecondary),
                    ),
            )
          : _buildForm(context, tx, palette),
    );
  }

  Widget _buildForm(
    BuildContext context,
    Transaction tx,
    AppThemeColors palette,
  ) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final cards = ref.watch(cardsProvider).valueOrNull ?? const <WalletCard>[];
    final category = cats.where((c) => c.id == _categoryId).firstOrNull;
    final card = cards.where((c) => c.id == _cardId).firstOrNull;
    final amountColor = _type == TransactionType.expense
        ? AppColors.expenseOf(context)
        : AppColors.incomeOf(context);

    final fieldRadius = BorderRadius.circular(AppConstants.controlRadius);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        12,
        AppConstants.pagePadding,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: fieldRadius,
          ),
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
            decoration: const InputDecoration(
              isCollapsed: true,
              filled: false,
              hintText: '0',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (_) => _markDirty(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TypeChip(
              label: 'Income',
              selected: _type == TransactionType.income,
              color: AppColors.incomeOf(context),
              onTap: () => setState(() {
                _type = TransactionType.income;
                _dirty = true;
              }),
            ),
            const SizedBox(width: 16),
            _TypeChip(
              label: 'Expense',
              selected: _type == TransactionType.expense,
              color: AppColors.primary,
              onTap: () => setState(() {
                _type = TransactionType.expense;
                _dirty = true;
              }),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _FieldLabel('Title'),
        _FilledInput(
          controller: _titleCtrl,
          hint: 'Title',
          capitalization: TextCapitalization.sentences,
          onChanged: _markDirty,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Category'),
        _BorderedPicker(
          icon: category?.icon ?? Icons.sell_outlined,
          label: category?.name ?? 'Category',
          leadingColor: category != null ? AppColors.primary : null,
          onTap: _pickCategory,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Card'),
        _BorderedPicker(
          icon: Icons.account_balance_wallet_outlined,
          label: card?.name ?? 'Account',
          onTap: _pickCard,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Date'),
        _BorderedPicker(
          icon: Icons.calendar_today_outlined,
          label: DateFormat('EEE, MMM d, yyyy').format(_date),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Time'),
        _BorderedPicker(
          icon: Icons.schedule_outlined,
          label: TimeOfDay.fromDateTime(_date).format(context),
          onTap: _pickTime,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Note'),
        _FilledInput(
          controller: _noteCtrl,
          hint: 'Notes (optional)',
          capitalization: TextCapitalization.sentences,
          maxLines: 2,
          onChanged: _markDirty,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : () => _confirmDelete(tx),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.expenseOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppThemeColors.of(context).textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FilledInput extends StatelessWidget {
  const _FilledInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.capitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final TextCapitalization capitalization;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: TextStyle(color: palette.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: palette.textTertiary),
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.controlRadius),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _BorderedPicker extends StatelessWidget {
  const _BorderedPicker({
    required this.icon,
    required this.label,
    required this.onTap,
    this.leadingColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.controlRadius),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.controlRadius),
            border: Border.all(
              color: palette.textTertiary.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              if (leadingColor != null)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: leadingColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 13, color: AppColors.white),
                )
              else
                Icon(icon, size: 20, color: palette.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? color : palette.textTertiary,
          ),
        ),
      ),
    );
  }
}
