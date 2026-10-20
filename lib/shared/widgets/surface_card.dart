import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'ios_pressable.dart';

enum SurfaceDepth { inset, outset, flat }

/// Solid rounded panel. One opaque fill, no gradient, shadow, or blur.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.depth = SurfaceDepth.outset,
    this.color,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final SurfaceDepth depth;
  final Color? color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  Color _fill(AppThemeColors palette, bool isLight) {
    if (color != null) return color!;
    if (depth != SurfaceDepth.inset) return palette.surface;
    // Recessed track: darker than the raised surface, still one opaque color.
    return Color.alphaBlend(
      AppColors.black.withValues(alpha: isLight ? 0.06 : 0.35),
      palette.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius =
        borderRadius ?? BorderRadius.circular(AppConstants.glassRadius);

    final card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: _fill(palette, isLight),
        borderRadius: radius,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return IosPressable(onTap: onTap, borderRadius: radius, child: card);
  }
}
