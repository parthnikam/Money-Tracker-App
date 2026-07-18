import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_boxes.dart';

const _themeModeKey = 'theme_mode';

/// Persisted app theme: system / light / dark.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_readInitial());

  static ThemeMode _readInitial() {
    final box = Hive.box(HiveBoxes.settings);
    final raw = box.get(_themeModeKey) as String?;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // product default stays dark
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(HiveBoxes.settings);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await box.put(_themeModeKey, value);
  }

  Future<void> toggleLightDark() async {
    // Treat system as dark for a simple two-way switch from settings.
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
