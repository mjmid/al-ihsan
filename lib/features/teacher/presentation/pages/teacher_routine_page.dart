import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/models/hive_models/routine_entry.dart';
import 'package:maktaba_ihsan/core/providers/settings_provider.dart';
import 'package:maktaba_ihsan/core/theme/neu_card.dart';
import 'package:uuid/uuid.dart';

class TeacherRoutinePage extends ConsumerStatefulWidget {
  const TeacherRoutinePage({super.key});

  @override
  ConsumerState<TeacherRoutinePage> createState() => _TeacherRoutinePageState();
}

class _TeacherRoutinePageState extends ConsumerState<TeacherRoutinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _days;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    final today = DateTime.now().weekday; // 1 = Monday ... 7 = Sunday
    _tabController.index = (today - 1).clamp(0, 6);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddRoutineSheet(BuildContext context, int initialDayIndex,
      {RoutineEntry? existingRoutine}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRoutineForm(
        initialDayIndex: initialDayIndex,
        existingRoutine: existingRoutine,
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, RoutineEntry routine, AppTranslations t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(t.delete,
                style: const TextStyle(fontWeight: FontWeight.normal)),
          ],
        ),
        content: Text(t.deleteRoutineConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await routine.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String appFontFamily = locale == 'ar'
        ? 'ArabicMyLotus'
        : (locale == 'ur' ? 'UrduNastaleeq' : 'BengaliSolaiman');
    final List<String> fontFallback = locale == 'ar'
        ? const ['BengaliSolaiman', 'UrduNastaleeq']
        : (locale == 'ur'
            ? const ['ArabicMyLotus', 'BengaliSolaiman']
            : const ['ArabicMyLotus', 'UrduNastaleeq']);

    _days = [t.mon, t.tue, t.wed, t.thu, t.fri, t.sat, t.sun];
    final todayWeekday = DateTime.now().weekday; // 1 = Monday ... 7 = Sunday

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            splashBorderRadius: BorderRadius.circular(14),
            labelColor: Colors.white,
            labelStyle: TextStyle(
              fontFamily: appFontFamily,
              fontFamilyFallback: fontFallback,
              fontWeight: FontWeight.normal,
              fontSize: locale == 'ur' ? 16 : 14,
            ),
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            unselectedLabelStyle: TextStyle(
              fontFamily: appFontFamily,
              fontFamilyFallback: fontFallback,
              fontWeight: FontWeight.normal,
              fontSize: locale == 'ur' ? 15 : 13,
            ),
            dividerColor: Colors.transparent,
            tabs: List.generate(7, (i) {
              final isToday = (i + 1) == todayWeekday;
              return Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _days[i],
                        style: TextStyle(
                          fontFamily: appFontFamily,
                          fontFamilyFallback: fontFallback,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.amberAccent
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentDayIndex = _tabController.index + 1;
          _showAddRoutineSheet(context, currentDayIndex);
        },
        icon: const Icon(Icons.add),
        label: Text(
          t.addRoutine,
          style: TextStyle(
            fontFamily: appFontFamily,
            fontFamilyFallback: fontFallback,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveHelper.routineBox.listenable(),
        builder: (context, Box<RoutineEntry> box, _) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1 = Monday
              final isToday = dayIndex == todayWeekday;

              // Filter routines that contain this day
              final routines = box.values
                  .where((r) => r.daysOfWeek.contains(dayIndex))
                  .toList();
              routines.sort((a, b) => a.startTime.compareTo(b.startTime));

              if (routines.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 44,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t.noRoutineToday,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                            fontFamily: appFontFamily,
                            fontFamilyFallback: fontFallback,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.addRoutinePrompt,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: appFontFamily,
                            fontFamilyFallback: fontFallback,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              _showAddRoutineSheet(context, dayIndex),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            t.addRoutine,
                            style: TextStyle(
                              fontFamily: appFontFamily,
                              fontFamilyFallback: fontFallback,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 12, bottom: 90),
                itemCount: routines.length + 1, // +1 for day header bar
                itemBuilder: (context, i) {
                  if (i == 0) {
                    // Day context header
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? theme.colorScheme.primary.withOpacity(0.12)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isToday
                                    ? theme.colorScheme.primary.withOpacity(0.3)
                                    : theme.colorScheme.outlineVariant
                                        .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  size: 16,
                                  color: isToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _days[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14,
                                    color: isToday
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontFamily: appFontFamily,
                                    fontFamilyFallback: fontFallback,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      locale == 'bn'
                                          ? 'আজ'
                                          : (locale == 'ur'
                                              ? 'آج'
                                              : (locale == 'ar'
                                                  ? 'اليوم'
                                                  : 'Today')),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  '${routines.length} ${t.classesCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: theme.colorScheme.primary,
                                    fontFamily: appFontFamily,
                                    fontFamilyFallback: fontFallback,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final routine = routines[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: NeuCard(
                      padding: const EdgeInsets.all(0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showAddRoutineSheet(context, dayIndex,
                            existingRoutine: routine),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Side: Time Slot Badge & Period Badge
                              Container(
                                width: 95,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(isDark ? 0.18 : 0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  border: Border(
                                    right: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (routine.periodNumber != null &&
                                        routine.periodNumber!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        margin:
                                            const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          routine.periodNumber!,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal,
                                            fontFamily: appFontFamily,
                                            fontFamilyFallback: fontFallback,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          routine.startTime,
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 15,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      width: 12,
                                      height: 1.5,
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.4),
                                    ),
                                    Text(
                                      routine.endTime,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Middle: Subject, Jamat & Period Details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.menu_book_rounded,
                                            size: 18,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              routine.subjectName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal,
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontFamily: appFontFamily,
                                                fontFamilyFallback:
                                                    fontFallback,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme.primaryContainer
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.school_outlined,
                                                    size: 13,
                                                    color: theme
                                                        .colorScheme.primary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${t.classJamat}: ${routine.className}',
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme.onSurface,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontFamily: appFontFamily,
                                                    fontFamilyFallback:
                                                        fontFallback,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (routine.roomNumber != null &&
                                              routine.roomNumber!.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .meeting_room_outlined,
                                                      size: 13,
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${t.roomNo}: ${routine.roomNumber}',
                                                    style: TextStyle(
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontFamily: appFontFamily,
                                                      fontFamilyFallback:
                                                          fontFallback,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Right Side: Quick Action Buttons
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (routine.reminderMinutes != null ||
                                        routine.nightBeforeAlarm)
                                      IconButton(
                                        icon: Icon(
                                          Icons.notifications_active_rounded,
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                        onPressed: () {},
                                        tooltip: routine.nightBeforeAlarm
                                            ? 'আগামিকাল ${routine.className} জামাতে আপনার দরস আছে।\nসময়: ${routine.nightBeforeAlarmTime ?? "21:00"}'
                                            : 'Alarm: ${routine.reminderMinutes}m',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined,
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.8),
                                          size: 20),
                                      onPressed: () => _showAddRoutineSheet(
                                          context, dayIndex,
                                          existingRoutine: routine),
                                      tooltip: t.editRoutine,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded,
                                          color: Colors.red.shade400,
                                          size: 20),
                                      onPressed: () =>
                                          _confirmDelete(context, routine, t),
                                      tooltip: t.delete,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}

class _AddRoutineForm extends ConsumerStatefulWidget {
  final int initialDayIndex;
  final RoutineEntry? existingRoutine;
  const _AddRoutineForm({
    required this.initialDayIndex,
    this.existingRoutine,
  });

  @override
  ConsumerState<_AddRoutineForm> createState() => _AddRoutineFormState();
}

class _AddRoutineFormState extends ConsumerState<_AddRoutineForm> {
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _roomController = TextEditingController();
  final _periodController = TextEditingController();
  final _startTimeController = TextEditingController(text: '08:00');
  final _endTimeController = TextEditingController(text: '09:00');
  final _nightBeforeAlarmTimeController = TextEditingController(text: '21:00');

  late List<String> _days;
  late Set<int> _selectedDays;

  int? _reminderMinutes;
  bool _nightBeforeAlarm = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      final r = widget.existingRoutine!;
      _subjectController.text = r.subjectName;
      _classController.text = r.className;
      _roomController.text = r.roomNumber ?? '';
      _periodController.text = r.periodNumber ?? '';
      _startTimeController.text = r.startTime;
      _endTimeController.text = r.endTime;
      _selectedDays = r.daysOfWeek.toSet();
      _reminderMinutes = r.reminderMinutes;
      _nightBeforeAlarm = r.nightBeforeAlarm;
      if (r.nightBeforeAlarmTime != null) {
        _nightBeforeAlarmTimeController.text = r.nightBeforeAlarmTime!;
      }
    } else {
      _selectedDays = {widget.initialDayIndex};
    }
    _subjectController.addListener(_updateUI);
    _classController.addListener(_updateUI);
    _startTimeController.addListener(_updateUI);
    _periodController.addListener(_updateUI);
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  void dispose() {
    _subjectController.removeListener(_updateUI);
    _classController.removeListener(_updateUI);
    _startTimeController.removeListener(_updateUI);
    _periodController.removeListener(_updateUI);
    _subjectController.dispose();
    _classController.dispose();
    _roomController.dispose();
    _periodController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _nightBeforeAlarmTimeController.dispose();
    super.dispose();
  }

  void _save() {
    if (_subjectController.text.trim().isEmpty || _selectedDays.isEmpty) return;

    final entryId = widget.existingRoutine?.id ?? const Uuid().v4();
    final entry = RoutineEntry(
      id: entryId,
      daysOfWeek: _selectedDays.toList(),
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      subjectName: _subjectController.text.trim(),
      className: _classController.text.trim(),
      roomNumber: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
      periodNumber: _periodController.text.trim().isEmpty
          ? null
          : _periodController.text.trim(),
      reminderMinutes: _reminderMinutes,
      nightBeforeAlarm: _nightBeforeAlarm,
      nightBeforeAlarmTime:
          _nightBeforeAlarm ? _nightBeforeAlarmTimeController.text : null,
    );
    HiveHelper.routineBox.put(entry.id, entry);
    Navigator.pop(context);
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && mounted) {
      final formatted =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  List<String> _getQuickPeriods(String locale) {
    if (locale == 'ur') {
      return [
        'پہلا گھنٹہ',
        'دوسرا گھنٹہ',
        'تیسرا گھنٹہ',
        'چوتھا گھنٹہ',
        'پانچواں گھنٹہ',
        'چھٹا گھنٹہ',
        'ساتواں گھنٹہ',
        'آٹھواں گھنٹہ',
      ];
    } else if (locale == 'ar') {
      return [
        'الحصة الأولى',
        'الحصة الثانية',
        'الحصة الثالثة',
        'الحصة الرابعة',
        'الحصة الخامسة',
        'الحصة السادسة',
        'الحصة السابعة',
        'الحصة الثامنة',
      ];
    } else if (locale == 'en') {
      return [
        '1st Period',
        '2nd Period',
        '3rd Period',
        '4th Period',
        '5th Period',
        '6th Period',
        '7th Period',
        '8th Period',
      ];
    } else {
      return [
        '১ম ঘণ্টা',
        '২য় ঘণ্টা',
        '৩য় ঘণ্টা',
        '৪র্থ ঘণ্টা',
        '৫ম ঘণ্টা',
        '৬ষ্ঠ ঘণ্টা',
        '৭ম ঘণ্টা',
        '৮ম ঘণ্টা',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.locale.languageCode;
    final theme = Theme.of(context);

    final String appFontFamily = locale == 'ar'
        ? 'ArabicMyLotus'
        : (locale == 'ur' ? 'UrduNastaleeq' : 'BengaliSolaiman');
    final List<String> fontFallback = locale == 'ar'
        ? const ['BengaliSolaiman', 'UrduNastaleeq']
        : (locale == 'ur'
            ? const ['ArabicMyLotus', 'BengaliSolaiman']
            : const ['ArabicMyLotus', 'UrduNastaleeq']);

    _days = [t.mon, t.tue, t.wed, t.thu, t.fri, t.sat, t.sun];
    final quickPeriods = _getQuickPeriods(locale);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existingRoutine != null
                        ? t.editRoutine
                        : t.addNewRoutine,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      fontFamily: appFontFamily,
                      fontFamilyFallback: fontFallback,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: t.cancel,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Subject Name
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: t.subjectLabel,
                prefixIcon: const Icon(Icons.menu_book_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Class & Room
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classController,
                    decoration: InputDecoration(
                      labelText: t.classJamat,
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _roomController,
                    decoration: InputDecoration(
                      labelText: t.roomNo,
                      prefixIcon: const Icon(Icons.meeting_room_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Period / Hour Number Input
            TextField(
              controller: _periodController,
              decoration: InputDecoration(
                labelText: t.periodNumberLabel,
                hintText: t.periodNumberHint,
                prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: _periodController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            setState(() => _periodController.clear()),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Quick Period Suggestion Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickPeriods.map((period) {
                  final isSelected = _periodController.text == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        period,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: appFontFamily,
                          fontFamilyFallback: fontFallback,
                          fontWeight: FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      showCheckmark: false,
                      onSelected: (val) {
                        setState(() {
                          _periodController.text = val ? period : '';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Time Pickers
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTimeController,
                    readOnly: true,
                    onTap: () => _pickTime(_startTimeController),
                    decoration: InputDecoration(
                      labelText: t.startTime,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _endTimeController,
                    readOnly: true,
                    onTap: () => _pickTime(_endTimeController),
                    decoration: InputDecoration(
                      labelText: t.endTime,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Days selector
            Text(
              t.selectDays,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontFamily: appFontFamily,
                fontFamilyFallback: fontFallback,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final dayId = i + 1;
                final isSelected = _selectedDays.contains(dayId);
                return FilterChip(
                  label: Text(
                    _days[i],
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      fontFamilyFallback: fontFallback,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedDays.add(dayId);
                      } else {
                        if (_selectedDays.length > 1) {
                          _selectedDays.remove(dayId);
                        }
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            // Reminder dropdown
            Text(
              t.alarmAndReminder,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontFamily: appFontFamily,
                fontFamilyFallback: fontFallback,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _reminderMinutes,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: null, child: Text(t.alarmOff)),
                const DropdownMenuItem(value: 5, child: Text('5 min')),
                const DropdownMenuItem(value: 10, child: Text('10 min')),
                const DropdownMenuItem(value: 15, child: Text('15 min')),
                const DropdownMenuItem(value: 30, child: Text('30 min')),
              ],
              onChanged: (val) => setState(() => _reminderMinutes = val),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                t.reminderNightBefore,
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontFamilyFallback: fontFallback,
                  fontWeight: FontWeight.normal,
                ),
              ),
              subtitle: Text(
                'আপনার আগামিকাল ${_startTimeController.text.isEmpty ? "___" : _startTimeController.text} টা থেকে ${_classController.text.isEmpty ? "___" : _classController.text} জামাতে ${_subjectController.text.isEmpty ? "___" : _subjectController.text} কিতাবের দরস আছে, মুতালায়া করুন।',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: appFontFamily,
                  fontFamilyFallback: fontFallback,
                ),
              ),
              value: _nightBeforeAlarm,
              onChanged: (val) => setState(() => _nightBeforeAlarm = val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            if (_nightBeforeAlarm) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _nightBeforeAlarmTimeController,
                readOnly: true,
                onTap: () => _pickTime(_nightBeforeAlarmTimeController),
                decoration: const InputDecoration(
                  labelText: 'রিমাইন্ডারের সময় (আগের দিন)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _subjectController.text.trim().isNotEmpty &&
                      _selectedDays.isNotEmpty
                  ? _save
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                t.saveBtn,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  fontFamily: appFontFamily,
                  fontFamilyFallback: fontFallback,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
