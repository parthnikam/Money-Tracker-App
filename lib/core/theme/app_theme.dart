import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_constants.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        palette: AppThemeColors.dark,
        income: AppColors.incomeDark,
        expense: AppColors.expenseDark,
        overlay: SystemUiOverlayStyle.light,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        palette: AppThemeColors.light,
        income: AppColors.income,
        expense: AppColors.expense,
        overlay: SystemUiOverlayStyle.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppThemeColors palette,
    required Color income,
    required Color expense,
    required SystemUiOverlayStyle overlay,
  }) {
    // Platform iOS → Cupertino scroll/page cues on Material widgets.
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: palette.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      splashColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.primarySoft,
        onSecondary: AppColors.onPrimary,
        error: expense,
        onError: AppColors.onPrimary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      extensions: [palette],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: palette.background,
        barBackgroundColor: palette.surface.withValues(alpha: 0.82),
        textTheme: CupertinoTextThemeData(
          primaryColor: palette.textPrimary,
          textStyle: TextStyle(
            fontFamily: GoogleFonts.inter().fontFamily,
            color: palette.textPrimary,
            fontSize: 17,
            letterSpacing: -0.24,
          ),
        ),
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    ).copyWith(
      // Slightly tighter tracking reads more SF-like on iOS.
      bodyLarge: base.textTheme.bodyLarge?.copyWith(letterSpacing: -0.2),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(letterSpacing: -0.15),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        letterSpacing: -0.4,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
      ),
    );

    final controlRadius = BorderRadius.circular(AppConstants.controlRadius);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlay.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: palette.background,
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.glassFillStrong),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: textTheme.bodyMedium,
        elevation: 8,
        shadowColor: AppColors.black.withValues(alpha: 0.2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceElevated,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? AppColors.black.withValues(alpha: 0.04)
            : AppColors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textTertiary,
          letterSpacing: -0.15,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
          letterSpacing: -0.15,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.glassFill,
        selectedColor: AppColors.primary.withValues(alpha: 0.22),
        labelStyle: textTheme.labelMedium!.copyWith(letterSpacing: -0.1),
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: AppColors.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(
        color: palette.glassFill,
        thickness: 0.5,
        space: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

/// Snappy scroll physics (fast deceleration, less rubber-band lag).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
