import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/di/providers.dart';
import '../../../features/cards/domain/wallet_card.dart';
import '../domain/category.dart';
import '../domain/transaction.dart';
import 'category_picker_sheet.dart';

/// Calculator-style add flow matching `ui_design/expenses.jpg`.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  bool _isTransfer = false;

  Category? _category;
  WalletCard? _account;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  /// Raw amount string for the display / keypad.
  String _amountRaw = '0';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Keypad ─────────────────────────────────────────────────

  void _onDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountRaw == '0' && d != '.') {
        _amountRaw = d;
      } else if (d == '.' && _amountRaw.contains('.')) {
        return;
      } else if (_amountRaw.contains('.') &&
          _amountRaw.split('.').last.length >= 2) {
        return;
      } else {
        _amountRaw += d;
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountRaw.length <= 1) {
        _amountRaw = '0';
      } else {
        _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1);
      }
    });
  }

  void _onOp(String op) {
    HapticFeedback.selectionClick();
    // Simple continuous calc: apply pending if any, then set op.
    setState(() {
      if (_pendingOp != null && _lhs != null) {
        _lhs = _apply(_lhs!, double.tryParse(_amountRaw) ?? 0, _pendingOp!);
        _amountRaw = _formatNum(_lhs!);
      } else {
        _lhs = double.tryParse(_amountRaw) ?? 0;
      }
      _pendingOp = op;
      _awaitingRhs = true;
    });
  }

  void _onEquals() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_pendingOp != null && _lhs != null) {
        final rhs = double.tryParse(_amountRaw) ?? 0;
        final result = _apply(_lhs!, rhs, _pendingOp!);
        _amountRaw = _formatNum(result);
        _lhs = null;
        _pendingOp = null;
        _awaitingRhs = false;
      }
    });
  }

  double? _lhs;
  String? _pendingOp;
  bool _awaitingRhs = false;

  double _apply(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? a : a / b;
      default:
        return b;
    }
  }

  String _formatNum(double n) {
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _onKey(String key) {
    if (_awaitingRhs &&
        (RegExp(r'^\d$').hasMatch(key) || key == '.') &&
        _pendingOp != null) {
      setState(() {
        _amountRaw = key == '.' ? '0.' : key;
        _awaitingRhs = false;
      });
      return;
    }
    if (key == '⌫') {
      _onBackspace();
    } else if (key == '+' || key == '-' || key == '×' || key == '÷') {
      _onOp(key);
    } else if (key == '=') {
      _onEquals();
    } else {
      _onDigit(key);
    }
  }

  double get _amountValue => double.tryParse(_amountRaw) ?? 0;

  String get _displayAmount {
    final v = _amountValue;
    return NumberFormat('#,##0.##').format(v);
  }

  // ── Pickers ────────────────────────────────────────────────

  Future<void> _pickCategory() async {
    final selected = await showCategoryPickerSheet(
      context,
      selectedId: _category?.id,
    );
    if (selected != null) setState(() => _category = selected);
  }

  Future<void> _pickAccount() async {
    final cards = ref.read(cardsProvider).valueOrNull ?? [];
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a card first')),
      );
      return;
    }
    final palette = AppThemeColors.of(context);
    final picked = await showModalBottomSheet<WalletCard>(
      context: context,
      backgroundColor: palette.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Select account',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              ...(() {
                final ordered = List<WalletCard>.from(cards)
                  ..sort((a, b) {
                    if (a.isPrimary == b.isPrimary) return 0;
                    return a.isPrimary ? -1 : 1;
                  });
                return ordered;
              })().map(
                (c) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.startColor.withValues(alpha: 0.25),
                    child: Icon(Icons.account_balance_wallet,
                        color: c.startColor),
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    c.isPrimary
                        ? '•••• ${c.lastFour} · Primary'
                        : '•••• ${c.lastFour}',
                  ),
                  trailing: _account?.id == c.id
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, c),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _account = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  // ── Save ───────────────────────────────────────────────────

  Future<void> _save() async {
    final amount = _amountValue;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount')),
      );
      return;
    }

    final cards = ref.read(cardsProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final account = _account ?? cards.primaryOrFirst;
    final category = _category ??
        (categories.isNotEmpty ? categories.first : null);

    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an account')),
      );
      return;
    }
    if (!_isTransfer && category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category')),
      );
      return;
    }

    setState(() => _saving = true);

    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final titleText = _titleCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    final title = titleText.isNotEmpty
        ? titleText
        : (_isTransfer
            ? 'Transfer'
            : (_type == TransactionType.income ? 'Income' : 'Expense'));

    final tx = Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: _isTransfer ? TransactionType.expense : _type,
      categoryId: category?.id ?? categories.first.id,
      cardId: account.id,
      date: when,
      note: note.isEmpty ? null : note,
      paymentMethod: _isTransfer ? 'Transfer' : 'Card',
    );

    final repo = ref.read(transactionRepositoryProvider);
    final cardRepo = ref.read(cardRepositoryProvider);
    await repo.add(tx);

    final delta = (_type == TransactionType.income && !_isTransfer)
        ? amount
        : -amount;
    await cardRepo.update(account.copyWith(balance: account.balance + delta));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final cards = ref.watch(cardsProvider).valueOrNull ?? [];
    ref.watch(categoriesProvider); // keep picker data warm

    // Always default to the primary (main) card for new expenses.
    _account ??= cards.primaryOrFirst;

    final dateLabel = DateFormat('MMM d, yyyy').format(_date);
    final timeLabel = _time.format(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('CANCEL'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: const Text('SAVE'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Type tabs ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TypeTab(
                    label: 'INCOME',
                    selected: !_isTransfer && _type == TransactionType.income,
                    onTap: () => setState(() {
                      _isTransfer = false;
                      _type = TransactionType.income;
                    }),
                  ),
                  _DividerDot(color: palette.textTertiary),
                  _TypeTab(
                    label: 'EXPENSE',
                    selected: !_isTransfer && _type == TransactionType.expense,
                    showCheck: !_isTransfer && _type == TransactionType.expense,
                    onTap: () => setState(() {
                      _isTransfer = false;
                      _type = TransactionType.expense;
                    }),
                  ),
                  _DividerDot(color: palette.textTertiary),
                  _TypeTab(
                    label: 'TRANSFER',
                    selected: _isTransfer,
                    onTap: () => setState(() => _isTransfer = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Account + Category ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PickerField(
                          icon: Icons.account_balance_wallet_outlined,
                          label: _account?.name ?? 'Account',
                          onTap: _pickAccount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PickerField(
                          icon: Icons.sell_outlined,
                          label: _isTransfer
                              ? '—'
                              : (_category?.name ?? 'Category'),
                          leadingColor: _category != null
                              ? AppColors.primary
                              : null,
                          onTap: _isTransfer ? null : _pickCategory,
                          enabled: !_isTransfer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Title + notes ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: palette.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: palette.textTertiary),
                      filled: true,
                      fillColor: palette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: palette.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Notes (optional)',
                      hintStyle: TextStyle(color: palette.textTertiary),
                      filled: true,
                      fillColor: palette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Amount display ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayAmount,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w300,
                              letterSpacing: -0.8,
                              color: palette.textPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _onBackspace,
                      icon: Icon(
                        Icons.backspace_outlined,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Keypad ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    // Number keys: a bit lighter in dark mode for readability.
                    final keyFace = isDark
                        ? Color.lerp(
                            palette.surface,
                            AppColors.white,
                            0.16,
                          )!
                        : Color.lerp(
                            palette.surface,
                            palette.textPrimary,
                            0.08,
                          )!;
                    final accentFace = isDark
                        ? Color.lerp(
                            palette.surface,
                            AppColors.primary,
                            0.28,
                          )!
                        : Color.lerp(
                            palette.surface,
                            AppColors.primary,
                            0.18,
                          )!;
                    return _CalculatorPad(
                      onKey: _onKey,
                      keyFace: keyFace,
                      textColor: palette.textPrimary,
                      accentFace: accentFace,
                    );
                  },
                ),
              ),
            ),

            // ── Date / time ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _pickDate,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        dateLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: palette.textTertiary.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickTime,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        timeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck && selected) ...[
              const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: selected ? AppColors.primary : palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text('|', style: TextStyle(color: color.withValues(alpha: 0.5)));
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.onTap,
    this.leadingColor,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? leadingColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final color = enabled ? palette.textPrimary : palette.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
                Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
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

class _CalculatorPad extends StatelessWidget {
  const _CalculatorPad({
    required this.onKey,
    required this.keyFace,
    required this.textColor,
    required this.accentFace,
  });

  final ValueChanged<String> onKey;
  final Color keyFace;
  final Color textColor;
  final Color accentFace;

  static const _keys = [
    ['+', '7', '8', '9'],
    ['-', '4', '5', '6'],
    ['×', '1', '2', '3'],
    ['÷', '0', '.', '='],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _keys.map((row) {
        return Expanded(
          child: Row(
            children: row.map((key) {
              final isOp = '+-×÷='.contains(key);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Material(
                    color: isOp ? accentFace : keyFace,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onKey(key),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: key == '=' || isOp ? 22 : 24,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
