/// ---------------------------------------------------------------------------
/// app_constants.dart
/// ---------------------------------------------------------------------------
/// Central home for every magic string, integer, and key used across the app.
/// Centralising constants here means a single place to update when values
/// change, and zero chance of typos from repeated inline literals.
/// ---------------------------------------------------------------------------

library app_constants;

// ─── API ─────────────────────────────────────────────────────────────────────

/// Base URL of the deployed Google Apps Script Web-App endpoint.
/// Replace this value after running `clasp deploy` or publishing via the
/// Google Sheets UI → Extensions → Apps Script → Deploy → New deployment.
const String kGasBaseUrl =
    'https://script.google.com/macros/s/AKfycbwAYg4oDtspNGFGMr6Bpt8YWYhF0Ao6tbYMCzriXCDjVF0EhZhH5g-MUmiTj3X3c-TiIw/exec';

/// Static API key that every request must include as a query/body parameter.
/// Set the same value in the GAS `doGet` / `doPost` guard clause.
const String kApiKey = 'YOUR_API_KEY_HERE';

/// Maximum number of seconds to wait for a connection to be established.
const int kApiTimeoutSeconds = 30;

/// Default number of rows returned per paginated GAS page request.
const int kPageSize = 300;

// ─── SYNC ─────────────────────────────────────────────────────────────────────

/// SharedPreferences key that stores the ISO-8601 timestamp of the last
/// successful Books delta-sync run.
const String kLastSyncBooksKey = 'last_sync_books';

/// SharedPreferences key that stores the ISO-8601 timestamp of the last
/// successful Users delta-sync run.
const String kLastSyncUsersKey = 'last_sync_users';

/// SharedPreferences key that stores the ISO-8601 timestamp of the last
/// successful Transactions delta-sync run.
const String kLastSyncTransactionsKey = 'last_sync_transactions';

/// Sentinel timestamp used on first-install (before any sync has occurred).
/// GAS queries for rows where `updated_at >= this timestamp`, which means
/// all rows are returned on the very first run.
const String kEpochTimestamp = '2000-01-01T00:00:00.000Z';

// ─── DATABASE ────────────────────────────────────────────────────────────────

/// SQLite database file name stored in the application documents directory.
const String kDbName = 'maktaba_ihsan.db';

/// Schema version — increment this when the DDL changes so that
/// `onUpgrade` migrations are triggered automatically by sqflite.
const int kDbVersion = 1;

/// SQLite table name for the Books catalogue.
const String kBooksTable = 'books';

/// SQLite table name for library members / teachers.
const String kUsersTable = 'users';

/// SQLite table name for issue / return transactions.
const String kTransactionsTable = 'transactions';

// ─── HIVE ────────────────────────────────────────────────────────────────────

/// Hive box name for teacher-authored notes (Markdown / rich-text blobs).
const String kTeacherNotesBox = 'teacher_notes';

/// Hive box name for the daily madrasa routine / timetable entries.
const String kRoutineBox = 'routine';

/// Hive box name for app-wide key-value settings (theme, language, etc.).
const String kSettingsBox = 'settings';

/// Hive box name for user-defined note folder / category metadata.
const String kNoteFoldersBox = 'note_folders';

// ─── SETTINGS KEYS ───────────────────────────────────────────────────────────

/// Hive/SharedPreferences key for the active theme mode.
/// Valid values: `'light'` | `'dark'` | `'system'`
const String kThemeModeKey = 'theme_mode';

/// Hive/SharedPreferences key for the active UI language.
/// Valid values: `'ar'` | `'bn'` | `'en'` | `'ur'`
const String kLanguageKey = 'language';

/// SharedPreferences key for the ID of the currently logged-in user.
const String kCurrentUserIdKey = 'current_user_id';

/// SharedPreferences key for the type of the currently logged-in user.
/// Values correspond to [UserType] enum names.
const String kCurrentUserTypeKey = 'current_user_type';

// ─── APP INFO ────────────────────────────────────────────────────────────────

/// Localised app name shown in the Bengali locale.
const String kAppName = 'মাকতাবাতু ইহসান';

/// English transliteration of the app name (used in metadata / SEO).
const String kAppNameEn = 'Maktaba Ihsan';

/// Maximum number of sync-queue operations dispatched to GAS simultaneously.
/// Keeping this at 1 prevents hitting Google's 30-req/min rate limit per user.
const int kMaxConcurrentSyncRequests = 1;

/// Seconds to wait between successive sync-queue dispatches.
const int kSyncQueueRetryDelaySeconds = 5;

/// Maximum number of times a failed sync operation is retried before being
/// permanently discarded from the queue.
const int kMaxRetryAttempts = 3;

// ─── LOCALISATION ────────────────────────────────────────────────────────────

/// Map of BCP-47 locale codes to their human-readable display names.
/// Used to build the language-picker UI in Settings.
const Map<String, String> kSupportedLocales = {
  'en': 'English',
  'bn': 'বাংলা',
  'ar': 'العربية',
  'ur': 'اردو',
};
