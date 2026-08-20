import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'providers.dart';

// Selected type filter (null = all active, special sentinel for inactive)
final userTypeFilterProvider = StateProvider<UserType?>((ref) => null);

// Search query filter
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Whether to show inactive users tab
final showInactiveUsersProvider = StateProvider<bool>((ref) => false);

// Users list
final usersListProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final typeFilter = ref.watch(userTypeFilterProvider);
  final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();
  final showInactive = ref.watch(showInactiveUsersProvider);
  final repository = ref.watch(userRepositoryProvider);

  var allUsers = await repository.getAllUsers();

  // Filter by active/archived
  if (showInactive) {
    allUsers = allUsers.where((u) => u.status == UserStatus.archived).toList();
  } else {
    // "সব" tab: only active users; other type filters also only active
    allUsers = allUsers.where((u) => u.status == UserStatus.active).toList();
    if (typeFilter != null) {
      allUsers = allUsers.where((u) => u.type == typeFilter).toList();
    }
  }

  if (searchQuery.isNotEmpty) {
    allUsers = allUsers.where((u) =>
      u.name.toLowerCase().contains(searchQuery) ||
      u.userId.toLowerCase().contains(searchQuery) ||
      (u.phone != null && u.phone!.toLowerCase().contains(searchQuery))
    ).toList();
  }

  return allUsers;
});
