import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ios_glass.dart';
import 'ios_pressable.dart';

enum GlassDepth { inset, outset, flat }

/// Apple-style frosted glass surface with bottom→top gradient.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.depth = GlassDepth.outset,
    this.color,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final GlassDepth depth;
  final Color? color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius =
        borderRadius ?? BorderRadius.circular(AppConstants.glassRadius);

    final shadows = switch (depth) {
      GlassDepth.outset => IosGlass.softElevation(isLight: isLight),
      GlassDepth.inset => [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isLight ? 0.06 : 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      GlassDepth.flat => <BoxShadow>[],
    };

    final gradient = color != null
        ? LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.alphaBlend(
                AppColors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                color!,
              ),
              Color.alphaBlend(
                AppColors.white.withValues(alpha: isLight ? 0.2 : 0.1),
                color!,
              ),
            ],
          )
        : IosGlass.surfaceGradient(isLight: isLight);

    // List rows use [GlassDepth.flat] — skip BackdropFilter there.
    // Live blur on every scrolling tile is the main source of scroll jank.
    final useBlur = depth != GlassDepth.flat;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient,
      ),
      child: child,
    );

    if (useBlur) {
      content = Stack(
        children: [
          content,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.2,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: radius.topLeft,
                    topRight: radius.topRight,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.0),
                      AppColors.white
                          .withValues(alpha: isLight ? 0.55 : 0.22),
                      AppColors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      // Lighter sigma keeps glass look without killing scroll FPS.
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      );
    }

    // Shadow must sit outside ClipRRect or it gets clipped (flat “web” look).
    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: content,
      ),
    );

    if (onTap == null) return card;

    return IosPressable(
      onTap: onTap,
      borderRadius: radius,
      child: card,
    );
  }
}
