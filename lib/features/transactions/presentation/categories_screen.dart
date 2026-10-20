import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/surface_card.dart';
import '../domain/category.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final ordered = list.sortedForDisplay();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: ordered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final c = ordered[i];
              return SurfaceCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: ListTile(
                  visualDensity: VisualDensity.compact,
                  minVerticalPadding: 0,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(c.icon, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: c.isDefault
                      ? Text(
                          'Default',
                          style: TextStyle(
                            color: AppThemeColors.of(context).textTertiary,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: c.isDefault
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.expenseOf(context),
                          ),
                          onPressed: () => ref
                              .read(categoryRepositoryProvider)
                              .delete(c.id),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final icons = [
      Icons.shopping_bag_outlined,
      Icons.fitness_center,
      Icons.school_outlined,
      Icons.pets,
      Icons.medical_services_outlined,
      Icons.devices,
      Icons.spa_outlined,
      Icons.music_note,
    ];
    var selectedIcon = icons.first;
    final colorValue = AppColors.categoryDefaultColorValue;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.of(context).surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New category',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: icons.map((icon) {
                      final selected = icon == selectedIcon;
                      return ChoiceChip(
                        label: Icon(icon, size: 18),
                        selected: selected,
                        onSelected: (_) => setModal(() => selectedIcon = icon),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: 'Create',
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final category = Category(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        iconCodePoint: selectedIcon.codePoint,
                        colorValue: colorValue,
                      );
                      await ref.read(categoryRepositoryProvider).add(category);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
