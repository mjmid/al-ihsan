import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'providers.dart';

/// ============================================================
/// AuthState — Immutable snapshot of authentication status
/// ============================================================
class AuthState {
  final String? userId;
  final String? userName;
  final String? userPhone;
  final UserType? userType;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.userId,
    this.userName,
    this.userPhone,
    this.userType,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Not logged in
  factory AuthState.unauthenticated() => const AuthState();

  /// Loading (during login attempt)
  factory AuthState.loading() => const AuthState(isLoading: true);

  /// Successfully authenticated
  factory AuthState.authenticated(User user) => AuthState(
        userId: user.userId,
        userName: user.name,
        userPhone: user.phone,
        userType: user.type,
        isAuthenticated: true,
      );

  /// Login failed
  factory AuthState.error(String message) => AuthState(
        isAuthenticated: false,
        errorMessage: message,
      );

  bool get isAdmin => userType == UserType.admin;
  bool get isTeacher => userType == UserType.teacher;
  bool get isStudent => userType == UserType.student;

  AuthState copyWith({
    String? userId,
    String? userName,
    String? userPhone,
    UserType? userType,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userType: userType ?? this.userType,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// ============================================================
/// AuthNotifier — Manages login, logout, session restore
/// ============================================================
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.unauthenticated()) {
    _restoreSession();
  }

  /// Attempt to restore last session from SharedPreferences.
  /// Called on app launch to keep user logged in.
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(kCurrentUserIdKey);
      final savedUserType = prefs.getString(kCurrentUserTypeKey);

      if (savedUserId == null || savedUserType == null) return;

      // Handle hardcoded SUPER_ADMIN case
      if (savedUserId == 'SUPER_ADMIN') {
        state = AuthState.authenticated(
          User(
            userId: 'SUPER_ADMIN',
            name: 'Super Admin',
            type: UserType.admin,
            status: UserStatus.active,
            lastUpdated: DateTime.now(),
          ),
        );
        return;
      }

      // Re-fetch user from local DB to ensure it still exists and is active
      final userRepo = _ref.read(userRepositoryProvider);
      final user = await userRepo.getUserById(savedUserId);

      if (user != null && user.status == UserStatus.active) {
        state = AuthState.authenticated(user);
      } else {
        // User archived or deleted — clear saved session
        await _clearSavedSession(prefs);
      }
    } catch (e) {
      // Silent failure — user will need to log in manually
    }
  }

  /// Attempt login with name/phone and PIN.
  ///
  /// [nameOrPhone] — Username, Phone, or Full Name
  /// [pin]         — Numeric PIN or Password
  ///
  /// Returns true on success, false on failure.
  Future<bool> login(String nameOrPhone, String pin) async {
    state = AuthState.loading();

    try {
      User? user;

      // -------------------------------------------------------------
      // HARDCODED SUPER ADMIN LOGIC
      // -------------------------------------------------------------
      if (nameOrPhone == 'maktabatuihsan@gmail.com' && pin == '01854019101') {
        user = User(
          userId: 'SUPER_ADMIN',
          name: 'Super Admin',
          type: UserType.admin,
          status: UserStatus.active,
          lastUpdated: DateTime.now(),
        );
      } else {
        final userRepo = _ref.read(userRepositoryProvider);
        user = await userRepo.authenticateUser(nameOrPhone, pin);

        if (user == null) {
          // Automatically sync and try again if local DB didn't find the user (e.g., fresh install)
          try {
            final syncService = await _ref.read(syncServiceProvider.future);
            await syncService.syncAll();
            user = await userRepo.authenticateUser(nameOrPhone, pin);
          } catch (_) {}
        }
      }

      if (user == null) {
        state = AuthState.error('নাম/ফোন বা PIN ভুল আছে। আবার চেষ্টা করুন।');
        return false;
      }

      if (user.status == UserStatus.archived) {
        state = AuthState.error('এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।');
        return false;
      }

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kCurrentUserIdKey, user.userId);
      await prefs.setString(kCurrentUserTypeKey, user.type.name);

      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error('লগইনে সমস্যা হয়েছে। পরে চেষ্টা করুন।');
      return false;
    }
  }

  /// Log out and clear saved session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSavedSession(prefs);
    state = AuthState.unauthenticated();
  }

  Future<void> _clearSavedSession(SharedPreferences prefs) async {
    await prefs.remove(kCurrentUserIdKey);
    await prefs.remove(kCurrentUserTypeKey);
  }
}

/// ============================================================
/// Provider
/// ============================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
