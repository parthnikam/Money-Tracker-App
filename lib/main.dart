import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/storage/hive_boxes.dart';
import 'core/storage/seed_data.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash visible while Hive init runs.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(HiveBoxes.transactions),
    Hive.openBox(HiveBoxes.categories),
    Hive.openBox(HiveBoxes.cards),
    Hive.openBox(HiveBoxes.budgets),
    Hive.openBox(HiveBoxes.savings),
    Hive.openBox(HiveBoxes.settings),
  ]);
  await seedIfEmpty();

  runApp(
    const ProviderScope(
      child: MoneyTrackerApp(),
    ),
  );

  FlutterNativeSplash.remove();
}
