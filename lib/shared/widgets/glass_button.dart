import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ios_glass.dart';
import 'ios_pressable.dart';

enum GlassButtonVariant { primary, secondary, destructive }

/// Native-feeling iOS glass control with bottom→top gradient.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final enabled = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(AppConstants.controlRadius);

    final Gradient gradient = switch (variant) {
      GlassButtonVariant.primary => IosGlass.accentGradient(),
      GlassButtonVariant.secondary =>
        IosGlass.controlGradient(isLight: isLight),
      GlassButtonVariant.destructive => LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.alphaBlend(
              AppColors.black.withValues(alpha: 0.2),
              AppColors.expense,
            ),
            Color.alphaBlend(
              AppColors.white.withValues(alpha: 0.12),
              AppColors.expenseDark,
            ),
          ],
        ),
    };

    final foreground = switch (variant) {
      GlassButtonVariant.primary => AppColors.onPrimary,
      GlassButtonVariant.secondary =>
        AppThemeColors.of(context).textPrimary,
      GlassButtonVariant.destructive => AppColors.onPrimary,
    };

    final button = Container(
      height: height,
      width: expand ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled ? IosGlass.controlShadow(isLight: isLight) : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: height,
                width: expand ? double.infinity : null,
                padding: EdgeInsets.symmetric(horizontal: expand ? 18 : 22),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: gradient,
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: foreground),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: foreground.withValues(
                                alpha: enabled ? 1 : 0.45,
                              ),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
              // Top specular highlight (does not cover full button text area).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.45,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.white.withValues(
                            alpha: variant == GlassButtonVariant.secondary
                                ? (isLight ? 0.45 : 0.14)
                                : 0.22,
                          ),
                          AppColors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return IosPressable(
      onTap: enabled ? onPressed : null,
      borderRadius: radius,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: button,
      ),
    );
  }
}

/// Compact glass icon button (e.g. app bar actions).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final palette = AppThemeColors.of(context);
    final radius = BorderRadius.circular(size / 2);

    return IosPressable(
      onTap: onPressed,
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: IosGlass.controlShadow(isLight: isLight),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: IosGlass.controlGradient(isLight: isLight),
              ),
              child: Icon(icon, size: 20, color: palette.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
