import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/currency/app_currency.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/di/providers.dart';
import '../../../core/storage/transaction_csv_export.dart';
import '../../../core/storage/transaction_csv_import.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _showCurrencyPicker(
    BuildContext context,
    AppCurrency current,
  ) async {
    final palette = AppThemeColors.of(context);
    final selected = await showModalBottomSheet<AppCurrency>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textTertiary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Display currency',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Changes how amounts are shown. Stored values are not converted.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: AppCurrency.supported.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: palette.textTertiary.withValues(alpha: 0.15),
                    ),
                    itemBuilder: (ctx, i) {
                      final c = AppCurrency.supported[i];
                      final isSelected = c.code == current.code;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.18),
                          child: Text(
                            c.symbol,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          c.code,
                          style: TextStyle(
                            color: palette.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await ref.read(currencyProvider.notifier).setCurrency(selected);
    }
  }

  Future<void> _exportCsv() async {
    if (_exporting || _importing) return;
    setState(() => _exporting = true);

    try {
      final transactions =
          await ref.read(transactionRepositoryProvider).getAll();
      final categories = await ref.read(categoryRepositoryProvider).getAll();
      final cards = await ref.read(cardRepositoryProvider).getAll();

      if (transactions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export')),
        );
        return;
      }

      final result = await TransactionCsvExport.export(
        transactions: transactions,
        categories: categories,
        cards: cards,
      );

      if (!mounted) return;

      final path = result.path;
      final message = path != null
          ? 'Exported ${result.rowCount} transactions\n$path'
          : 'Exported ${result.rowCount} transactions (${result.fileName})';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: path == null
              ? null
              : SnackBarAction(
                  label: 'Copy path',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: path));
                  },
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importCsv() async {
    if (_importing || _exporting) return;

    try {
      const typeGroup = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
        mimeTypes: ['text/csv', 'text/comma-separated-values', 'text/plain'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      setState(() => _importing = true);

      final bytes = await file.readAsBytes();
      // Strip UTF-8 BOM if present; decode as UTF-8.
      final csv = utf8.decode(bytes, allowMalformed: true);

      final categories = await ref.read(categoryRepositoryProvider).getAll();
      final cards = await ref.read(cardRepositoryProvider).getAll();

      final result = await TransactionCsvImport.importAndAppend(
        csv: csv,
        categories: categories,
        cards: cards,
        transactionRepository: ref.read(transactionRepositoryProvider),
        cardRepository: ref.read(cardRepositoryProvider),
      );

      if (!mounted) return;

      final parts = <String>[
        if (result.importedCount > 0)
          'Imported ${result.importedCount} transactions'
        else
          'No new transactions imported',
        if (result.skippedDuplicates > 0)
          '${result.skippedDuplicates} already present (skipped)',
        if (result.rowErrors.isNotEmpty)
          '${result.rowErrors.length} row(s) had errors',
      ];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(parts.join(' · ')),
          duration: Duration(
            seconds: result.rowErrors.isEmpty ? 4 : 6,
          ),
          action: result.rowErrors.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Details',
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Import issues'),
                        content: SingleChildScrollView(
                          child: Text(result.rowErrors.take(20).join('\n')),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final budgets = ref.watch(budgetsProvider);
    final transactions = ref.watch(transactionsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);
    final palette = AppThemeColors.of(context);
    final isLight = themeMode == ThemeMode.light ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.light);

    final txCount = transactions.valueOrNull?.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            16,
            AppConstants.pagePadding,
            120,
          ),
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage categories, budgets, and data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLight
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Light mode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isLight ? 'Using light theme' : 'Using dark theme',
                      style: TextStyle(
                        color: palette.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    value: isLight,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                            value ? ThemeMode.light : ThemeMode.dark,
                          );
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.payments_outlined,
                    title: 'Currency',
                    subtitle: '${currency.name} (${currency.symbol})',
                    onTap: () => _showCurrencyPicker(context, currency),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.category_outlined,
                    title: 'Categories',
                    subtitle: categories.when(
                      data: (c) => '${c.length} categories',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    onTap: () => context.push('/categories'),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.pie_chart_outline,
                    title: 'Budgets',
                    subtitle: budgets.when(
                      data: (b) => '${b.length} active',
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                    onTap: () => context.push('/budgets'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.add_card_outlined,
                    title: 'Add card / wallet',
                    subtitle: 'Spend sources',
                    onTap: () => context.push('/cards/add'),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Add transaction',
                    subtitle: 'Income or expense',
                    onTap: () => context.push('/transactions/add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export transactions (CSV)',
                    subtitle: _exporting
                        ? 'Preparing export…'
                        : txCount == null
                            ? 'Backup all local transactions'
                            : 'Export $txCount transactions to CSV',
                    onTap: (_exporting || _importing) ? () {} : _exportCsv,
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.file_upload_outlined,
                    title: 'Import transactions (CSV)',
                    subtitle: _importing
                        ? 'Importing…'
                        : 'Append rows from an export-format CSV',
                    onTap: (_exporting || _importing) ? () {} : _importCsv,
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: '${AppConstants.appName} · local-first (Hive)',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: AppConstants.appName,
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Private personal finance tracker.\n\n'
                            'Data storage: transactions, categories, cards, and budgets '
                            'are saved on this device with Hive and persist across app launches.\n\n'
                            'Export / import: Settings → Export or Import transactions (CSV). '
                            'Import appends new rows (existing ids are skipped) and never '
                            'uploads data unless you share a file yourself.',
                      );
                    },
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: palette.textTertiary, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: palette.textTertiary),
    );
  }
}
