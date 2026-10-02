import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/domain/roster/daily_roster_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/daily_roster_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/draft_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/daily_roster_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_roster_page.dart';
import '../gallery_environment.dart';

@widgetbook.UseCase(
    name: 'Realtime editing and partial saves', type: DailyRosterView)
Widget liveRoster(BuildContext context) =>
    ProductPreview(builder: (_) => const _LiveRoster());

class _LiveRoster extends StatefulWidget {
  const _LiveRoster();
  @override
  State<_LiveRoster> createState() => _LiveRosterState();
}

class _LiveRosterState extends State<_LiveRoster> {
  final date = BusinessDate('2026-10-02');
  final drafts = MemoryDraftStore();
  late final repo = MemoryRosterRepository(
      access: RosterAccess('synthetic', 'manager', ['a']),
      sites: const [
        ClassSite('a', '合成永安據點')
      ],
      students: const [
        StudentSummary('s1', '合成小禾'),
        StudentSummary('s2', '合成小葵')
      ],
      enrollments: [
        period('s1'),
        period('s2')
      ]);
  String kind = 'attendance';
  bool failed = false, revoked = false;
  Enrollment period(String id) => Enrollment('e_$id',
      studentId: id,
      locationId: 'a',
      startDate: date,
      endDateExclusive: BusinessDate('9999-12-31'));
  @override
  void dispose() {
    repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Wrap(spacing: 8, children: [
          TextButton(
              onPressed: () => setState(() =>
                  kind = kind == 'attendance' ? 'performance' : 'attendance'),
              child: const Text('切換出席／表現')),
          TextButton(
              onPressed: () {
                if (!repo.students.any((s) => s.id == 's3')) {
                  repo.students = [
                    ...repo.students,
                    const StudentSummary('s3', '合成新同學')
                  ];
                  repo.enrollments = [...repo.enrollments, period('s3')];
                  repo.notify();
                }
              },
              child: const Text('模擬另一台新增學生')),
          FilterChip(
              label: const Text('模擬小葵儲存失敗'),
              selected: failed,
              onSelected: (v) => setState(() {
                    failed = v;
                    if (v) {
                      repo.failStudents.add('s2');
                    } else {
                      repo.failStudents.clear();
                    }
                  })),
          FilterChip(
              label: const Text('模擬撤銷權限'),
              selected: revoked,
              onSelected: (v) => setState(() {
                    revoked = v;
                    repo.access =
                        v ? null : RosterAccess('synthetic', 'manager', ['a']);
                    repo.notify();
                  })),
        ]),
        Expanded(
            child: BlocProvider(
                key: ValueKey(kind),
                create: (_) => DailyRosterCubit(
                    kind: kind,
                    service: DailyRosterService(repo),
                    draftStore: drafts,
                    date: date)
                  ..start(),
                child: const DailyRosterPage())),
      ]);
}
