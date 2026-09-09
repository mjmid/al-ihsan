import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/user_providers.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'add_edit_user_page.dart';
import 'user_detail_page.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(userSearchQueryProvider);
    _searchController.text = query;
    if (query.isNotEmpty) {
      _isSearchOpen = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final usersAsync = ref.watch(usersListProvider);
    final selectedType = ref.watch(userTypeFilterProvider);
    final showInactive = ref.watch(showInactiveUsersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !showInactive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (showInactive) {
          ref.read(showInactiveUsersProvider.notifier).state = false;
        }
      },
      child: Scaffold(
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
              preferredSize: Size.fromHeight(_isSearchOpen ? 104 : 52),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expandable search bar
                    if (_isSearchOpen)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 6.0),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: showInactive
                                  ? '${t.inactive} ${t.members} ${t.searchHint}'
                                  : t.searchHint,
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: colorScheme.primary, size: 20),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      tooltip: 'মুছে ফেলুন',
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(userSearchQueryProvider.notifier).state = '';
                                        setState(() {});
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    tooltip: 'বন্ধ করুন',
                                    onPressed: () {
                                      setState(() {
                                        _isSearchOpen = false;
                                        _searchFocusNode.unfocus();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              ref.read(userSearchQueryProvider.notifier).state = value;
                              setState(() {});
                            },
                          ),
                        ),
                      ),

                    // Filter chips row with Search Icon to the left of 'সব'
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        children: [
                          // Search Icon Button to the left of 'সব'
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _isSearchOpen = !_isSearchOpen;
                                if (_isSearchOpen) {
                                  _searchFocusNode.requestFocus();
                                } else {
                                  _searchFocusNode.unfocus();
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (_isSearchOpen || _searchController.text.isNotEmpty)
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (_isSearchOpen || _searchController.text.isNotEmpty)
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 16,
                                    color: (_isSearchOpen || _searchController.text.isNotEmpty)
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  if (_searchController.text.isNotEmpty && !_isSearchOpen) ...[
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 80),
                                      child: Text(
                                        _searchController.text,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _searchController.clear();
                                          ref.read(userSearchQueryProvider.notifier).state = '';
                                        });
                                      },
                                      child: Icon(Icons.close_rounded,
                                          size: 14, color: colorScheme.onPrimary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          _buildMemberChip(
                            label: t.all,
                            isSelected: !showInactive && selectedType == null,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            onTap: () {
                              if (showInactive) {
                                ref.read(showInactiveUsersProvider.notifier).state = false;
                              }
                              ref.read(userTypeFilterProvider.notifier).state = null;
                            },
                          ),
                          const SizedBox(width: 8),
                          ...UserType.values.map((type) {
                            final isSelected = !showInactive && selectedType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _buildMemberChip(
                                label: _translateUserType(type, t),
                                isSelected: isSelected,
                                colorScheme: colorScheme,
                                isDark: isDark,
                                onTap: () {
                                  if (showInactive) {
                                    ref.read(showInactiveUsersProvider.notifier).state = false;
                                  }
                                  ref.read(userTypeFilterProvider.notifier).state = type;
                                },
                              ),
                            );
                          }),
                          Container(
                            height: 20,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            color: colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          _buildInactiveChip(
                            label: t.inactive,
                            isSelected: showInactive,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            onTap: () {
                              ref.read(showInactiveUsersProvider.notifier).state = !showInactive;
                              ref.read(userTypeFilterProvider.notifier).state = null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          showInactive ? Icons.person_off_outlined : Icons.people_outline,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          showInactive ? t.noInactiveMembers : t.noMembers,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                        if (showInactive) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.read(showInactiveUsersProvider.notifier).state = false;
                            },
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: Text(t.backToActiveMembers),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showInactive && index == 0) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_off_outlined,
                                      size: 18, color: Colors.red.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.inactiveMembersList,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      ref.read(showInactiveUsersProvider.notifier).state = false;
                                    },
                                    icon: const Icon(Icons.arrow_back, size: 14),
                                    label: Text(t.backToActiveMembers),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      foregroundColor: Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Padding(
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
                                              '${t.memberId}: ${user.userId}',
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
                      ),
                    ],
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
    ),
    );
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.principal:
        return Icons.workspace_premium;
      case UserType.educationSecretary:
        return Icons.menu_book;
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
      case UserType.principal:
        return t.principal;
      case UserType.educationSecretary:
        return t.educationSecretary;
      case UserType.teacher:
        return t.teacher;
      case UserType.student:
        return t.student;
    }
  }

  Widget _buildMemberChip({
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryColor =
        isDark ? const Color(0xFF10B981) : const Color(0xFF047857);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark
                    ? const Color(0xFF1F2937)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : colorScheme.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? Colors.grey.shade300
                      : colorScheme.onSurfaceVariant),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveChip({
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.red.shade700
                : (isDark
                    ? Colors.red.shade900.withOpacity(0.2)
                    : Colors.red.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.red.shade700
                  : Colors.red.withOpacity(0.35),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.red.shade700.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? Colors.redAccent.shade100
                        : Colors.red.shade700),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? Colors.redAccent.shade100
                          : Colors.red.shade700),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
