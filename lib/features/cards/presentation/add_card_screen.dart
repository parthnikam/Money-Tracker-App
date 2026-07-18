import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../shared/widgets/glass_button.dart';
import '../domain/wallet_card.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastFourCtrl = TextEditingController();
  final _holderCtrl = TextEditingController(text: 'You');
  final _balanceCtrl = TextEditingController(text: '0');

  int _paletteIndex = 0;
  bool _saving = false;

  static const _palettes = [
    (0xFFEA526F, 0xFF9E2A40),
    (0xFF22C55E, 0xFF166534),
    (0xFF3B82F6, 0xFF1E3A8A),
    (0xFFF59E0B, 0xFF92400E),
    (0xFF070600, 0xFF3A3934),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastFourCtrl.dispose();
    _holderCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final palette = _palettes[_paletteIndex];
    final existing = await ref.read(cardRepositoryProvider).getAll();
    final card = WalletCard(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      lastFour: _lastFourCtrl.text.trim().padLeft(4, '0'),
      holderName: _holderCtrl.text.trim(),
      balance: double.parse(_balanceCtrl.text),
      gradientStart: palette.$1,
      gradientEnd: palette.$2,
      // First card becomes the primary spend account.
      isPrimary: existing.isEmpty || existing.every((c) => !c.isPrimary),
    );

    await ref.read(cardRepositoryProvider).add(card);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add card'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
                        colors: [Color(_palettes[i].$1), Color(_palettes[i].$2)],
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
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
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
              decoration: const InputDecoration(
                labelText: 'Starting balance',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
              label: 'Save card',
            ),
          ],
        ),
      ),
    );
  }
}
