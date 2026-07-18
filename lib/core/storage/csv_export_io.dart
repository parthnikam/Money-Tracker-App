import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Writes export bytes using dart:io only (VM / mobile / desktop).
Future<String> writeCsvBytesToDisk(Uint8List bytes, String fileName) async {
  Directory? dir;

  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    dir = Directory(p.join(home, 'Documents', 'MoneyTracker', 'exports'));
  } else {
    dir = Directory(p.join(Directory.systemTemp.path, 'MoneyTracker', 'exports'));
  }

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);

  // Best-effort reveal on desktop.
  try {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', file.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dir.path]);
    }
  } catch (_) {}

  return file.path;
}
