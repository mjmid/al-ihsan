import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maktaba_ihsan/core/providers/auth_provider.dart';
import 'package:maktaba_ihsan/core/providers/providers.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/widgets/curved_bottom_nav.dart';
import 'package:maktaba_ihsan/features/books/presentation/pages/book_list_page.dart';
import 'package:maktaba_ihsan/features/settings/presentation/pages/settings_page.dart';
import 'package:maktaba_ihsan/features/teacher/presentation/pages/teacher_shelf_page.dart';
import 'package:maktaba_ihsan/features/teacher/presentation/pages/teacher_routine_page.dart';
import 'package:maktaba_ihsan/features/teacher/presentation/pages/teacher_notes_page.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  int _selectedIndex = 0;

  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final teacherName = authState.userName ?? 'শিক্ষক';
    final t = ref.watch(translationProvider);

    final pages = [
      const BookListPage(isAdmin: false), // কিতাব খুঁজুন
      const TeacherShelfPage(), // আমার সেলফ
      const TeacherRoutinePage(), // রুটিন
      const TeacherNotesPage(), // নোটস
      const SettingsPage(), // সেটিংস
    ];

    final titles = [
      t.bookList,
      t.myShelf,
      t.classRoutine,
      t.personalNotes,
      t.settings,
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: MadrasaAppBarTitle(title: titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : () async {
              setState(() => _isSyncing = true);
              try {
                final syncService = await ref.read(syncServiceProvider.future);
                await syncService.syncAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ডাটাবেস রিলোড হয়েছে!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                 if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('রিলোড করতে সমস্যা হয়েছে!'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isSyncing = false);
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: CurvedBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          CurvedNavItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            label: t.searchNav,
            gradientColors: const [
              Color(0xFF34d399),
              Color(0xFF059669)
            ], // Green
          ),
          CurvedNavItem(
            icon: Icons.collections_bookmark_outlined,
            activeIcon: Icons.collections_bookmark,
            label: t.shelfNav,
            gradientColors: const [
              Color(0xFF60A5FA),
              Color(0xFF2563EB)
            ], // Blue
          ),
          CurvedNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month,
            label: t.routineNav,
            gradientColors: const [
              Color(0xFFFBBF24),
              Color(0xFFD97706)
            ], // Amber
          ),
          CurvedNavItem(
            icon: Icons.note_alt_outlined,
            activeIcon: Icons.note_alt,
            label: t.notesNav,
            gradientColors: const [
              Color(0xFFF472B6),
              Color(0xFFDB2777)
            ], // Pink
          ),
          CurvedNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: t.settings,
            gradientColors: const [
              Color(0xFFf472b6),
              Color(0xFFdb2777)
            ], // Pink
          ),
        ],
      ),
    );
  }
}
