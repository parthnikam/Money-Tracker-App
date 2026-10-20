import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../shared/widgets/glass_button.dart';
import '../domain/wallet_card.dart';
import 'delete_card.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key, this.cardId});

  /// When set, screen edits the existing card instead of creating one.
  final String? cardId;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _lastFourCtrl = TextEditingController();
  final _holderCtrl = TextEditingController(text: 'You');
  final _balanceCtrl = TextEditingController(text: '0');

  int _paletteIndex = 0;
  bool _saving = false;
  bool _loaded = false;
  WalletCard? _existing;

  static const _palettes = [
    (0xFFEA526F, 0xFF9E2A40),
    (0xFF22C55E, 0xFF166534),
    (0xFF3B82F6, 0xFF1E3A8A),
    (0xFFF59E0B, 0xFF92400E),
    (0xFF070600, 0xFF3A3934),
  ];

  bool get _isEditing => widget.cardId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bankCtrl.dispose();
    _lastFourCtrl.dispose();
    _holderCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _hydrateFrom(WalletCard card) {
    _existing = card;
    _nameCtrl.text = card.name;
    _bankCtrl.text = card.bankName;
    _lastFourCtrl.text = card.lastFour;
    _holderCtrl.text = card.holderName;
    _balanceCtrl.text = card.balance == card.balance.roundToDouble()
        ? card.balance.toStringAsFixed(0)
        : card.balance.toStringAsFixed(2);

    final match = _palettes.indexWhere(
      (p) => p.$1 == card.gradientStart && p.$2 == card.gradientEnd,
    );
    _paletteIndex = match >= 0 ? match : 0;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final palette = _palettes[_paletteIndex];
    final repo = ref.read(cardRepositoryProvider);

    if (_isEditing && _existing != null) {
      final updated = _existing!.copyWith(
        name: _nameCtrl.text.trim(),
        bankName: _bankCtrl.text.trim(),
        lastFour: _lastFourCtrl.text.trim().padLeft(4, '0'),
        holderName: _holderCtrl.text.trim(),
        balance: double.parse(_balanceCtrl.text),
        gradientStart: palette.$1,
        gradientEnd: palette.$2,
      );
      await repo.update(updated);
    } else {
      final existing = await repo.getAll();
      final card = WalletCard(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        bankName: _bankCtrl.text.trim(),
        lastFour: _lastFourCtrl.text.trim().padLeft(4, '0'),
        holderName: _holderCtrl.text.trim(),
        balance: double.parse(_balanceCtrl.text),
        gradientStart: palette.$1,
        gradientEnd: palette.$2,
        // First card becomes the primary spend account.
        isPrimary: existing.isEmpty || existing.every((c) => !c.isPrimary),
      );
      await repo.add(card);
    }

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final card = _existing;
    if (card == null || _saving) return;
    final removed = await confirmDeleteCard(context, ref, card);
    if (removed && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_loaded) {
      final cardsAsync = ref.watch(cardsProvider);
      return cardsAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit card')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit card')),
          body: Center(child: Text('$e')),
        ),
        data: (cards) {
          final card = cards.where((c) => c.id == widget.cardId).firstOrNull;
          if (card == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Edit card'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ),
              body: const Center(child: Text('Card not found')),
            );
          }
          // Hydrate once when data arrives.
          if (!_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _loaded) return;
              setState(() => _hydrateFrom(card));
            });
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Edit card')),
            body: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit card' : 'Add card'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color(_palettes[_paletteIndex].$1),
                    Color(_palettes[_paletteIndex].$2),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameCtrl.text.isEmpty ? 'Card name' : _nameCtrl.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (_bankCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _bankCtrl.text.trim(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '••••  ${_lastFourCtrl.text.isEmpty ? '0000' : _lastFourCtrl.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 2,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_palettes.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _paletteIndex = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(_palettes[i].$1),
                          Color(_palettes[i].$2),
                        ],
                      ),
                      border: _paletteIndex == i
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Wallet name'),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bankCtrl,
              decoration: const InputDecoration(
                labelText: 'Bank name',
                hintText: 'Chase, HDFC, Revolut…',
                counterText: '',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 32,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastFourCtrl,
              decoration: const InputDecoration(labelText: 'Last 4 digits'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.length != 4 ? 'Enter 4 digits' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _holderCtrl,
              decoration: const InputDecoration(labelText: 'Holder name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _balanceCtrl,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Balance' : 'Starting balance',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 28),
            GlassButton(
              onPressed: _saving ? null : _save,
              isLoading: _saving,
              label: _isEditing ? 'Save changes' : 'Save card',
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              GlassButton(
                variant: GlassButtonVariant.destructive,
                icon: Icons.delete_outline,
                label: 'Remove card',
                onPressed: _saving ? null : _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
