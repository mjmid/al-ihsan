import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/database/hive_helper.dart';
import 'app/app.dart';

/// ============================================================
/// MAKTABA IHSAN — Application Entry Point
/// ============================================================
///
/// Boot sequence:
///   1. Initialize sqflite FFI (for Desktop/Windows support)
///   2. Initialize Hive (for Teacher Notes, Routine, Settings)
///   3. Initialize sqflite database (create tables + indexes)
///   4. Wrap app in ProviderScope (Riverpod)
///   5. Run the app
/// ============================================================

Future<void> main() async {
  // Ensure Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: sqflite Desktop/Web Support ─────────────────────────────────
  // On Windows/Linux/macOS, sqflite needs FFI initialization.
  // On Web, it needs FFI Web initialization.
  // On Android/iOS, this is handled natively — no action needed.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('✅ sqflite FFI Web initialized for web platform.');
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('✅ sqflite FFI initialized for desktop platform.');
  }

  // ── Step 2: Initialize Hive ───────────────────────────────────────────────
  // Hive stores Teacher Notes, Routine, and App Settings locally.
  // These are NEVER synced to the server.
  await HiveHelper.initialize();
  debugPrint('✅ Hive initialized. Boxes: notes, routine, settings, folders.');

  // ── Step 3: Initialize sqflite DB (warm up the singleton) ─────────────────
  // Calling getInstance() triggers table creation on first launch.
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.repairBookStatuses();
  debugPrint('✅ SQLite database initialized and repaired: $kDbName');

  // ── Step 4: Run App ───────────────────────────────────────────────────────
  // ProviderScope is the root of Riverpod's dependency injection tree.
  runApp(
    const ProviderScope(
      child: MaktabaApp(),
    ),
  );
}
