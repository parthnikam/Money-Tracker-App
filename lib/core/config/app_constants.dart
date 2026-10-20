abstract final class AppConstants {
  static const String appName = 'OctoFin';
  /// Default display currency symbol; prefer [CurrencyFormatter.symbol].
  static const String currencySymbol = '\$';

  /// Brand logo. Launcher icons, the site icon, and the native splash are
  /// generated from this file.
  static const String logoAsset = 'assets/logo.png';

  /// iOS continuous-corner-ish radii.
  static const double glassRadius = 18;
  static const double glassRadiusSm = 14;
  static const double glassRadiusLg = 26;
  static const double controlRadius = 14;
  static const double navBarHeight = 58;
  static const double pagePadding = 20;
}
