import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_button.dart';
import '../domain/budget.dart';

class AddSavingsScreen extends ConsumerStatefulWidget {
  const AddSavingsScreen({super.key});

  @override
  ConsumerState<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends ConsumerState<AddSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _currentCtrl = TextEditingController(text: '0');
  final _targetCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final plan = SavingsPlan(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      currentAmount: double.parse(_currentCtrl.text),
      targetAmount: double.parse(_targetCtrl.text),
      iconCodePoint: Icons.savings_outlined.codePoint,
      colorValue: AppColors.primary.toARGB32(),
    );

    await ref.read(savingsRepositoryProvider).add(plan);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New savings plan'),
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
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Plan name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _currentCtrl,
              decoration: const InputDecoration(
                labelText: 'Current amount',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) {
                if (v == null || double.tryParse(v) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _targetCtrl,
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a target';
                return null;
              },
            ),
            const SizedBox(height: 28),
            GlassButton(
              onPressed: _saving ? null : _save,
              isLoading: _saving,
              label: 'Create plan',
            ),
          ],
        ),
      ),
    );
  }
}
