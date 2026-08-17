import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track if an admin is currently viewing the app as a teacher.
/// Defaults to false. When true, the Admin Dashboard is swapped for the Teacher Dashboard.
final actingAsTeacherProvider = StateProvider<bool>((ref) => false);
