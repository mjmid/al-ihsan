import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../repositories/book_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/sync_queue_service.dart';

/// ============================================================
/// MAKTABA IHSAN — Central Providers File
/// ============================================================
/// Wires the entire dependency injection tree using Riverpod.
///
///   DatabaseHelper (singleton)
///       ↓
///   Repositories (BookRepo, UserRepo, TransactionRepo)
///       ↓
///   ApiService (Dio-based GAS client)
///       ↓
///   SyncQueueService (offline queue)
///       ↓
///   SyncService (orchestrator)
/// ============================================================

// ─────────────────────────────────────────────────────────────────────────────
// INFRASTRUCTURE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// SharedPreferences instance — used for sync timestamps.
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// SQLite DatabaseHelper singleton — uses `.instance` (not a factory method).
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Dio-based Google Apps Script API client.
/// ApiService uses a private constructor `ApiService._()` — accessed via provider.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService.instance;
});

/// Sync Queue — manages offline operation queue.
final syncQueueProvider =
    StateNotifierProvider<SyncQueueNotifier, List<SyncOperation>>(
  (ref) => SyncQueueNotifier(),
);

/// Sync Service — orchestrates delta sync and initial bulk sync.
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final api = ref.watch(apiServiceProvider);
  return SyncService(api: api, dbHelper: dbHelper, prefs: prefs);
});

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Book Repository — all book-related local DB operations.
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  final syncQueue = ref.watch(syncQueueProvider.notifier);
  return BookRepository(db: dbHelper, syncQueue: syncQueue);
});

/// User Repository — authentication and user management.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  final syncQueue = ref.watch(syncQueueProvider.notifier);
  return UserRepository(db: dbHelper, syncQueue: syncQueue);
});

/// Transaction Repository — book issue and return operations.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  final syncQueue = ref.watch(syncQueueProvider.notifier);
  return TransactionRepository(db: dbHelper, syncQueue: syncQueue);
});

// ─────────────────────────────────────────────────────────────────────────────
// CONNECTIVITY PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// Simple connectivity state — true = online, false = offline.
/// Full implementation will be wired in Step 4 (Background Sync).
final isOnlineProvider = StateProvider<bool>((ref) => true);
