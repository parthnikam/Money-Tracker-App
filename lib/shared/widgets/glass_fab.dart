import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/ios_glass.dart';
import 'ios_pressable.dart';

/// Accent glass FAB with bottom→top gradient (iOS control feel).
class GlassFab extends StatelessWidget {
  const GlassFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(18);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IosPressable(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: radius,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              ...IosGlass.controlShadow(isLight: isLight),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: IosGlass.accentGradient(),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 24,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.white.withValues(alpha: 0.28),
                              AppColors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(icon, color: AppColors.onPrimary, size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
