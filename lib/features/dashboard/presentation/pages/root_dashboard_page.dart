import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/core/providers/mode_provider.dart';
import 'package:maktaba_ihsan/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:maktaba_ihsan/features/teacher/presentation/pages/teacher_dashboard_page.dart';
import 'package:maktaba_ihsan/features/auth/presentation/pages/login_page.dart';
import 'package:maktaba_ihsan/core/models/user_model.dart';

class RootDashboardPage extends ConsumerWidget {
  const RootDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final actingAsTeacher = ref.watch(actingAsTeacherProvider);

    if (authState.userId == null) {
      // Not logged in, although we shouldn't reach here normally
      return const LoginPage();
    }

    if (authState.userType == UserType.admin && !actingAsTeacher) {
      return const AdminDashboardPage();
    }

    // Either user is a teacher, or admin is acting as a teacher
    return const TeacherDashboardPage();
  }
}
