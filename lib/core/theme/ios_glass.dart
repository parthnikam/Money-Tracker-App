import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradients and shadows for the accent button, icon button, and FAB.
///
/// Cards do not use this. A card gradient or blurred shadow is repainted on
/// every scroll frame. Do not add `BackdropFilter` here either.
abstract final class IosGlass {
  /// Primary / filled control glass (accent tint).
  static LinearGradient accentGradient() {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Color.alphaBlend(
          AppColors.black.withValues(alpha: 0.18),
          AppColors.primary,
        ),
        Color.alphaBlend(
          AppColors.white.withValues(alpha: 0.18),
          AppColors.primarySoft,
        ),
      ],
      stops: const [0.0, 1.0],
    );
  }

  /// Secondary / neutral control glass.
  static LinearGradient controlGradient({required bool isLight}) {
    if (isLight) {
      return LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.black.withValues(alpha: 0.06),
          AppColors.white.withValues(alpha: 0.92),
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        AppColors.white.withValues(alpha: 0.06),
        AppColors.white.withValues(alpha: 0.18),
      ],
    );
  }

  /// Soft top-edge specular (drawn as a hairline gradient border feel).
  static LinearGradient topSpecular({required bool isLight}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.white.withValues(alpha: isLight ? 0.75 : 0.28),
        AppColors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.45],
    );
  }

  static List<BoxShadow> softElevation({
    required bool isLight,
    double y = 8,
    double blur = 20,
  }) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isLight ? 0.08 : 0.45),
        blurRadius: blur,
        offset: Offset(0, y),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: AppColors.white.withValues(alpha: isLight ? 0.55 : 0.04),
        blurRadius: 0.5,
        offset: const Offset(0, -0.5),
      ),
    ];
  }

  static List<BoxShadow> controlShadow({required bool isLight}) {
    return [
      BoxShadow(
        color: AppColors.black.withValues(alpha: isLight ? 0.1 : 0.35),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: -1,
      ),
      BoxShadow(
        color: AppColors.white.withValues(alpha: isLight ? 0.65 : 0.08),
        blurRadius: 0.5,
        offset: const Offset(0, -0.5),
      ),
    ];
  }
}
