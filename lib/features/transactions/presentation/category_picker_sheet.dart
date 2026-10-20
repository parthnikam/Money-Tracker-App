import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/glass_button.dart';
import '../domain/category.dart';

/// Full-screen-ish sheet matching `ui_design/categories.jpg`:
/// circular icon grid + optional add category.
Future<Category?> showCategoryPickerSheet(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CategoryPickerSheet(selectedId: selectedId),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppThemeColors.of(context);
    final categories = ref.watch(categoriesProvider);
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.textTertiary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: categories.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories yet',
                        style: TextStyle(color: palette.textTertiary),
                      ),
                    );
                  }
                  final ordered = list.sortedForDisplay();
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 6,
                      mainAxisExtent: 82,
                    ),
                    itemCount: ordered.length,
                    itemBuilder: (context, i) {
                      final c = ordered[i];
                      final selected = c.id == selectedId;
                      return _CategoryGridItem(
                        category: c,
                        selected: selected,
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCategory(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.55),
                    ),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    'ADD NEW CATEGORY',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategory(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final icons = [
      Icons.child_care,
      Icons.spa,
      Icons.receipt_long,
      Icons.directions_car,
      Icons.checkroom,
      Icons.school,
      Icons.devices,
      Icons.movie,
      Icons.restaurant,
      Icons.favorite,
      Icons.home,
      Icons.verified_user,
      Icons.account_balance_wallet,
      Icons.shopping_cart,
      Icons.groups,
      Icons.sports_tennis,
      Icons.autorenew,
      Icons.request_quote,
      Icons.phone_iphone,
      Icons.directions_bus,
    ];
    var selectedIcon = icons[8];
    // All new categories use the solid accent (same visual style).
    final colorValue = AppColors.categoryDefaultColorValue;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.of(context).surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  const SizedBox(height: 14),
                  const Text('Icon'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final icon = icons[i];
                        final selected = icon == selectedIcon;
                        return ChoiceChip(
                          label: Icon(icon, size: 18),
                          selected: selected,
                          onSelected: (_) =>
                              setModal(() => selectedIcon = icon),
                        );
                      },
                    ),
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
                      await ref
                          .read(categoryRepositoryProvider)
                          .add(category);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        Navigator.pop(context, category);
                      }
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

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Uniform brand accent for every category icon.
              color: AppColors.primary,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
              border: selected
                  ? Border.all(color: AppColors.white, width: 2)
                  : null,
            ),
            child: Icon(
              category.icon,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : palette.textPrimary,
              letterSpacing: -0.1,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
