import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maktaba_ihsan/core/database/hive_helper.dart';
import 'package:maktaba_ihsan/core/l10n/app_translations.dart';
import 'package:maktaba_ihsan/core/models/hive_models/routine_entry.dart';
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
    final today = DateTime.now().weekday;
    _tabController.index = today - 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddRoutineSheet(BuildContext context, int initialDayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRoutineForm(initialDayIndex: initialDayIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    _days = [t.mon, t.tue, t.wed, t.thu, t.fri, t.sat, t.sun];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
            ),
            splashBorderRadius: BorderRadius.circular(16),
            labelColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            dividerColor: Colors.transparent,
            tabs: _days
                .map((d) => Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(d),
                      ),
                    ))
                .toList(),
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
              // Filter routines that contain this day
              final routines = box.values
                  .where((r) => r.daysOfWeek.contains(dayIndex))
                  .toList();
              routines.sort((a, b) => a.startTime.compareTo(b.startTime));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: routines.length + 1,
                itemBuilder: (context, i) {
                  if (i == routines.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showAddRoutineSheet(context, dayIndex),
                          icon: const Icon(Icons.add),
                          label: Text(t.addRoutine),
                        ),
                      ),
                    );
                  }

                  final routine = routines[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: NeuCard(
                      padding: const EdgeInsets.all(0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Side (Time Slot)
                            Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    routine.startTime,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '-',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    routine.endTime,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Middle Side (Details)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      routine.subjectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.class_outlined,
                                            size: 16,
                                            color: Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${t.classJamat}: ${routine.className}',
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (routine.roomNumber != null &&
                                        routine.roomNumber!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.meeting_room_outlined,
                                              size: 16,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${t.roomNo}: ${routine.roomNumber}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Right Side (Actions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (routine.reminderMinutes != null ||
                                      routine.nightBeforeAlarm)
                                    IconButton(
                                      icon: Icon(
                                        Icons.alarm_on,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      ),
                                      onPressed: () {},
                                      tooltip: routine.nightBeforeAlarm 
                                          ? 'Alarm: ${routine.nightBeforeAlarmTime ?? "21:00"} (Previous Night)'
                                          : 'Alarm is active',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 36, minHeight: 36),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 22),
                                    onPressed: () => routine.delete(),
                                    tooltip: 'Delete',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  const _AddRoutineForm({required this.initialDayIndex});

  @override
  ConsumerState<_AddRoutineForm> createState() => _AddRoutineFormState();
}

class _AddRoutineFormState extends ConsumerState<_AddRoutineForm> {
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _roomController = TextEditingController();
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
    _selectedDays = {widget.initialDayIndex};
  }

  void _save() {
    if (_subjectController.text.isEmpty || _selectedDays.isEmpty) return;

    final entry = RoutineEntry(
      id: const Uuid().v4(),
      daysOfWeek: _selectedDays.toList(),
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      subjectName: _subjectController.text,
      className: _classController.text,
      roomNumber: _roomController.text,
      reminderMinutes: _reminderMinutes,
      nightBeforeAlarm: _nightBeforeAlarm,
      nightBeforeAlarmTime: _nightBeforeAlarm ? _nightBeforeAlarmTimeController.text : null,
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationProvider);
    _days = [t.mon, t.tue, t.wed, t.thu, t.fri, t.sat, t.sun];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            Text(
              t.addNewRoutine,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                  labelText: t.subjectLabel,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classController,
                    decoration: InputDecoration(
                        labelText: t.classJamat,
                        border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _roomController,
                    decoration: InputDecoration(
                        labelText: t.roomNo,
                        border: const OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                        suffixIcon: const Icon(Icons.access_time)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endTimeController,
                    readOnly: true,
                    onTap: () => _pickTime(_endTimeController),
                    decoration: InputDecoration(
                        labelText: t.endTime,
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.access_time)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(t.selectDays,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final dayId = i + 1;
                final isSelected = _selectedDays.contains(dayId);
                return FilterChip(
                  label: Text(_days[i]),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedDays.add(dayId);
                      } else {
                        _selectedDays.remove(dayId);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(t.alarmAndReminder,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
              title: Text(t.reminderNightBefore),
              subtitle: Text(t.reminderNightBeforeDesc),
              value: _nightBeforeAlarm,
              onChanged: (val) => setState(() => _nightBeforeAlarm = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300)),
            ),
            if (_nightBeforeAlarm) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _nightBeforeAlarmTimeController,
                readOnly: true,
                onTap: () => _pickTime(_nightBeforeAlarmTimeController),
                decoration: InputDecoration(
                  labelText: 'রিমাইন্ডারের সময় (আগের দিন)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.access_time),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(t.saveBtn, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
