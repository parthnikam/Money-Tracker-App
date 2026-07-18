import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_constants.dart';
import '../core/currency/currency_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/utils/currency_formatter.dart';

class MoneyTrackerApp extends ConsumerStatefulWidget {
  const MoneyTrackerApp({super.key});

  @override
  ConsumerState<MoneyTrackerApp> createState() => _MoneyTrackerAppState();
}

class _MoneyTrackerAppState extends ConsumerState<MoneyTrackerApp> {
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    // Rebuild the tree when currency changes so all formatted amounts update.
    final currency = ref.watch(currencyProvider);
    CurrencyFormatter.apply(currency);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: _router,
      builder: (context, child) {
        final palette = AppThemeColors.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlay = (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: palette.background,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
