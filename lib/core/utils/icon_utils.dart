import 'package:flutter/material.dart';

/// Icons allowed for categories / savings (stored as code points in Hive).
///
/// Release builds tree-shake Material Icons and reject runtime
/// `IconData(codePoint, …)`. Every value here must be a **const** [Icons]
/// constant so the font subset can be computed at compile time.
const List<IconData> kAppSelectableIcons = <IconData>[
  // Default seed categories
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
  Icons.payments,
  // Categories screen / picker extras
  Icons.shopping_bag_outlined,
  Icons.fitness_center,
  Icons.school_outlined,
  Icons.pets,
  Icons.medical_services_outlined,
  Icons.spa_outlined,
  Icons.music_note,
  // Savings plans
  Icons.flight_takeoff,
  Icons.shield_outlined,
  Icons.savings_outlined,
  // Safe fallbacks used in UI
  Icons.receipt_long_outlined,
  Icons.category,
];

/// codePoint → const IconData (same instances as [kAppSelectableIcons]).
final Map<int, IconData> _iconByCodePoint = {
  for (final icon in kAppSelectableIcons) icon.codePoint: icon,
};

/// Resolves a stored Material icon code point without non-const [IconData].
///
/// Unknown code points (legacy data) fall back to [Icons.category].
IconData iconFromCodePoint(int codePoint) {
  return _iconByCodePoint[codePoint] ?? Icons.category;
}
