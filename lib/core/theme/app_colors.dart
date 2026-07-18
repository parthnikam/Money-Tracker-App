import 'package:flutter/material.dart';

/// Brand and semantic colors shared by both themes.
/// Mode-specific surfaces/text/glass live in [AppThemeColors].
///
/// Core palette: black `#070600`, white `#F7F7FF`, accent `#EA526F`.
abstract final class AppColors {
  static const Color black = Color(0xFF070600);
  static const Color white = Color(0xFFF7F7FF);
  static const Color primary = Color(0xFFEA526F);
  static const Color primarySoft = Color(0xFFF07189);
  static const Color primaryMuted = Color(0xFFC43D58);
  static const Color onPrimary = Color(0xFFF7F7FF);

  /// Income / expense amounts.
  static const Color income = Color(0xFF63D672);
  static const Color expense = Color(0xFFE03616);
  static const Color chartGreen = Color(0xFF63D672);

  /// Same brand colors in dark mode for consistency.
  static const Color incomeDark = Color(0xFF63D672);
  static const Color expenseDark = Color(0xFFE03616);

  static const List<Color> cardGradients = [
    Color(0xFFEA526F),
    Color(0xFF9E2A40),
  ];

  /// Stats dial palette (lavender → violet → cyan → soft rose).
  static const List<Color> dialColors = [
    Color(0xFFE5D9F2),
    Color(0xFFCDC1FF),
    Color(0xFFA594F9),
    Color(0xFF7371FC),
    Color(0xFF01BAEF),
    Color(0xFFE49AB0),
  ];

  /// Kept for any non-dial accent ramps; mirrors dial set.
  static const List<Color> accentScale = dialColors;

  /// Alias used by charts / dials.
  static const List<Color> chartDots = dialColors;

  /// Pick a color along [dialColors] for dial segment `index` of `total`.
  static Color accentHueAt(int index, {int total = 1}) {
    if (dialColors.isEmpty) return primary;
    if (total <= 1) return dialColors[dialColors.length ~/ 2];
    // Cycle through the palette first; lerp only if more segments than colors.
    if (total <= dialColors.length) {
      return dialColors[index.clamp(0, dialColors.length - 1)];
    }
    final t = (index / (total - 1)).clamp(0.0, 1.0);
    final pos = t * (dialColors.length - 1);
    final lo = pos.floor().clamp(0, dialColors.length - 1);
    final hi = pos.ceil().clamp(0, dialColors.length - 1);
    if (lo == hi) return dialColors[lo];
    return Color.lerp(dialColors[lo], dialColors[hi], pos - lo)!;
  }

  /// Category icon circles always use brand accent (same style for all).
  static Color categoryDefaultColor([int index = 0]) => primary;

  static int get categoryDefaultColorValue => primary.toARGB32();

  static Color incomeOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? incomeDark
        : income;
  }

  static Color expenseOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? expenseDark
        : expense;
  }
}

/// Surfaces, text, and glass tokens that change with light/dark mode.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassHighlight,
    required this.glassShadow,
    required this.navBar,
    required this.navInactive,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassHighlight;
  final Color glassShadow;
  final Color navBar;
  final Color navInactive;

  static const dark = AppThemeColors(
    background: AppColors.black,
    surface: Color(0xFF12110C),
    surfaceElevated: Color(0xFF1A1914),
    textPrimary: AppColors.white,
    textSecondary: Color(0xFFB8B8C4),
    textTertiary: Color(0xFF6E6E78),
    glassFill: Color(0x14F7F7FF),
    glassFillStrong: Color(0x1FF7F7FF),
    glassHighlight: Color(0x28F7F7FF),
    glassShadow: Color(0x80000000),
    navBar: Color(0xE612110C),
    navInactive: Color(0xFF6E6E78),
  );

  static const light = AppThemeColors(
    background: AppColors.white,
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: AppColors.black,
    textSecondary: Color(0xFF5C5C66),
    textTertiary: Color(0xFF8E8E99),
    glassFill: Color(0x0F070600),
    glassFillStrong: Color(0x14FFFFFF),
    glassHighlight: Color(0x99FFFFFF),
    glassShadow: Color(0x1A070600),
    navBar: Color(0xF2F7F7FF),
    navInactive: Color(0xFF8E8E99),
  );

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ?? AppThemeColors.dark;
  }

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassHighlight,
    Color? glassShadow,
    Color? navBar,
    Color? navInactive,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassShadow: glassShadow ?? this.glassShadow,
      navBar: navBar ?? this.navBar,
      navInactive: navInactive ?? this.navInactive,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
    );
  }
}
