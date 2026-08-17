import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'providers.dart';

// Selected type filter
final userTypeFilterProvider = StateProvider<UserType?>((ref) => null);

// Search query filter
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Users list
final usersListProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final typeFilter = ref.watch(userTypeFilterProvider);
  final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();
  final repository = ref.watch(userRepositoryProvider);

  var users = await repository.getAllUsers(type: typeFilter);
  
  if (searchQuery.isNotEmpty) {
    users = users.where((u) => 
      u.name.toLowerCase().contains(searchQuery) || 
      u.userId.toLowerCase().contains(searchQuery) ||
      (u.phone != null && u.phone!.toLowerCase().contains(searchQuery))
    ).toList();
  }
  
  return users;
});
