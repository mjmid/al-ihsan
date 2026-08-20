import 'package:flutter/material.dart';
import '../../../../core/widgets/filter_segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/user_providers.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'add_edit_user_page.dart';
import 'user_detail_page.dart';

class UserListPage extends ConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationProvider);
    final usersAsync = ref.watch(usersListProvider);
    final selectedType = ref.watch(userTypeFilterProvider);
    final showInactive = ref.watch(showInactiveUsersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditUserPage(),
            ),
          ).then((_) => ref.invalidate(usersListProvider));
        },
        child: const Icon(Icons.person_add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 0,
            pinned: true,
            floating: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(130),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'খুঁজুন...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      onChanged: (value) {
                        ref.read(userSearchQueryProvider.notifier).state =
                            value;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Active type filters
                        if (!showInactive)
                          Expanded(
                            child: FilterSegmentedControl<UserType?>(
                              items: const [null, ...UserType.values],
                              selected: selectedType,
                              labelBuilder: (type) {
                                if (type == null) return t.all;
                                return _translateUserType(type, t);
                              },
                              onChanged: (type) {
                                ref.read(userTypeFilterProvider.notifier).state = type;
                              },
                            ),
                          ),
                        if (!showInactive) const SizedBox(width: 8),
                        // নিষ্ক্রিয় tab
                        GestureDetector(
                          onTap: () {
                            ref.read(showInactiveUsersProvider.notifier).state =
                                !showInactive;
                            // Reset type filter when switching
                            ref.read(userTypeFilterProvider.notifier).state = null;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: showInactive
                                  ? Colors.red.shade700
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'নিষ্ক্রিয়',
                              style: TextStyle(
                                color: showInactive
                                    ? Colors.white
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(t.noMembers),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: NeuCard(
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserDetailPage(user: user),
                                ),
                              ).then((_) => ref.invalidate(usersListProvider));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(_getUserTypeIcon(user.type),
                                                size: 14,
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(
                                              _translateUserType(user.type, t),
                                              style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.badge_outlined,
                                                size: 14,
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(
                                              t.memberId + ': ${user.userId}',
                                              style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        if (user.phone != null &&
                                            user.phone!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone_outlined,
                                                  size: 14,
                                                  color: colorScheme
                                                      .onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.phone!,
                                                style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: user.status == UserStatus.active
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: user.status == UserStatus.active
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      user.status == UserStatus.active
                                          ? t.active
                                          : t.inactive,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: user.status == UserStatus.active
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: users.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverFillRemaining(
              child: Center(child: Text('${t.error}: $e')),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.teacher:
        return Icons.person;
      case UserType.student:
        return Icons.school;
    }
  }

  String _translateUserType(UserType type, AppTranslations t) {
    switch (type) {
      case UserType.admin:
        return t.admin;
      case UserType.teacher:
        return t.teacher;
      case UserType.student:
        return t.student;
    }
  }
}
