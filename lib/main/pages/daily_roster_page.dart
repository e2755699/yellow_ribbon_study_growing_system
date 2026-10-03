import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../design_system/presentation/system_theme_scope.dart';
import '../../design_system/presentation/components/system_page.dart';
import '../../domain/roster/daily_roster_cubit.dart';
import '../../domain/roster/roster_models.dart';
import '../components/roster/daily_roster_view.dart';
import '../components/roster/performance_record_card.dart';

class DailyRosterPage extends StatefulWidget {
  const DailyRosterPage({super.key});
  @override
  State<DailyRosterPage> createState() => _DailyRosterPageState();
}

class _DailyRosterPageState extends State<DailyRosterPage>
    with WidgetsBindingObserver {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      context.read<DailyRosterCubit>().persist();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SystemThemeScope(
      builder: (context) => BlocBuilder<DailyRosterCubit, DailyRosterState>(
              builder: (context, state) {
            final cubit = context.read<DailyRosterCubit>();
            final roster = state.roster;
            final records = cubit.kind == 'attendance'
                ? roster?.attendance
                : roster?.performance;
            final counts = cubit.counts;
            final rows = [
              for (final member in cubit.visibleMembers)
                RosterRowViewData(
                  id: member.student.id,
                  name: member.student.name,
                  values: cubit.values(member.student.id),
                  dirty: state.drafts.containsKey(member.student.id),
                  enabled: cubit.canEdit(member.student.id),
                  error: state.rowErrors[member.student.id],
                  needsConfirmation: records?[member.student.id] != null &&
                      records![member.student.id]!.provenance != 'confirmed',
                  notice: state.drafts.containsKey(member.student.id)
                      ? '尚未儲存'
                      : records?[member.student.id] != null &&
                              records![member.student.id]!.provenance !=
                                  'confirmed'
                          ? '歷史資料待確認（僅核對過的欄位列入統計）'
                          : null,
                )
            ];
            final orphanIds = {
              ...?roster?.orphanStudentIds,
              ...state.drafts.keys
            }.difference(
                roster?.members.map((row) => row.student.id).toSet() ?? {});
            for (final sid in orphanIds) {
              final record = records?[sid] ??
                  roster?.attendance[sid] ??
                  roster?.performance[sid];
              rows.add(RosterRowViewData(
                  id: sid,
                  name: record?.nameSnapshot.isNotEmpty == true
                      ? record!.nameSnapshot
                      : '待核對學生',
                  values: cubit.values(sid),
                  enabled: false,
                  orphan: true,
                  dirty: state.drafts.containsKey(sid),
                  notice: '歷史就讀關係待核對，未列入正常名冊統計',
                  error: state.rowErrors[sid]));
            }
            return SystemPage(
                title: cubit.kind == 'attendance' ? '每日出席' : '每日表現',
                scaffoldKey: scaffoldKey,
                onBeforeExit: cubit.saveBeforeExit,
                showSaveConfirmation: false,
                child: DailyRosterView(
                  kind: cubit.kind,
                  dateLabel: state.date.value,
                  locationId: state.locationId,
                  sites: state.sites,
                  rows: rows,
                  loading: state.loading,
                  error: state.error,
                  notice: [
                    if (kIsWeb) '此瀏覽器的未儲存草稿只保留到頁面關閉，請先儲存再離開。',
                    if (state.notice != null) state.notice!,
                  ].join('\n'),
                  saving: state.saving,
                  canSave:
                      cubit.hasUnsavedChanges && state.access?.enabled == true,
                  summary: roster == null
                      ? '名冊尚未確認'
                      : '名冊 ${counts.total} 位${cubit.kind == 'attendance' ? ' · 已點名 ${counts.marked} · 未點名 ${counts.unmarked}' : ' · 已評分 ${counts.marked} · 未評分 ${counts.unmarked}'} · 搜尋結果 ${cubit.visibleMembers.length} 位${counts.unverified > 0 ? ' · 歷史待確認 ${counts.unverified} 位' : ''}${roster.session?.status == SessionStatus.cancelled ? ' · 本日不上課' : roster.session?.status == SessionStatus.held ? ' · 本日有上課' : ' · 課次待確認'}${roster.fromCache ? ' · 離線／等待雲端確認' : ''}',
                  onSave: cubit.saveBeforeExit,
                  onRetry: cubit.retry,
                  onConfirmSession: cubit.canSetSession &&
                          roster?.session?.status != SessionStatus.held
                      ? () => cubit.setSession(SessionStatus.held)
                      : null,
                  onCancelSession: cubit.canSetSession &&
                          state.access?.isManager == true &&
                          roster?.session?.status == SessionStatus.held
                      ? () => _cancelSession(context, cubit)
                      : null,
                  onSearch: cubit.search,
                  onStatusFilter: cubit.filterStatus,
                  onLocationChanged: (id) => cubit.open(state.date, id),
                  onPickDate: () async {
                    final chosen = await showDatePicker(
                        context: context,
                        initialDate: state.date.calendar,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (chosen != null && state.locationId != null) {
                      await cubit.open(
                          BusinessDate.fromCalendar(chosen), state.locationId!);
                    }
                  },
                  onEdit: cubit.edit,
                  onDiscard: cubit.discard,
                  onKeepLocal: (sid) => _reviewConflict(context, cubit, sid),
                  onReviewEnrollment: state.access?.isManager == true
                      ? (sid) async {
                          if (!await cubit.persist() || !context.mounted) {
                            return;
                          }
                          await context.push("/studentDetail/view/$sid");
                        }
                      : null,
                  onConfirm: cubit.confirm,
                  onExpand: (sid) => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                          value: cubit,
                          child: Dialog.fullscreen(
                              child: Scaffold(
                                  appBar: AppBar(
                                      title: const Text('表現編輯'),
                                      leading: IconButton(
                                          tooltip: '返回清單',
                                          icon: const Icon(Icons.close),
                                          onPressed: () =>
                                              Navigator.of(dialogContext)
                                                  .pop())),
                                  body: BlocBuilder<DailyRosterCubit, DailyRosterState>(
                                      builder: (context, current) => SingleChildScrollView(
                                          padding: const EdgeInsets.all(24),
                                          child: PerformanceRecordCard(
                                              studentName: rows
                                                  .firstWhere((row) => row.id == sid)
                                                  .name,
                                              values: cubit.values(sid),
                                              onChanged: cubit.canEdit(sid) ? (field, value) => cubit.edit(sid, field, value) : null,
                                              notice: current.drafts.containsKey(sid) ? '尚未儲存，返回清單後儲存' : null))))))),
                ));
          }));
  Future<void> _reviewConflict(
      BuildContext context, DailyRosterCubit cubit, String sid) async {
    final draft = cubit.state.drafts[sid];
    if (draft == null) return;
    final roster = cubit.state.roster;
    final remote = (cubit.kind == 'attendance'
                ? roster?.attendance
                : roster?.performance)?[sid]
            ?.values ??
        {};
    const labels = {
      'status': '出席狀態',
      'leaveReason': '請假原因',
      'performanceRating': '整體表現',
      'remarks': '備註',
      'excellentCharacters': '品格標籤',
      ...PerformanceRecordCard.metrics
    };
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('核對這筆修改'),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('請確認雲端內容，再決定是否用你的修改覆蓋同一欄位。'),
                      for (final field in draft.patch.keys)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                                '${labels[field] ?? field}\n原先：${draft.base[field] ?? "未填"}\n雲端：${remote[field] ?? "未填"}\n你的修改：${draft.patch[field] ?? "未填"}')),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('返回')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('確認保留我的修改'))
                ]));
    if (accepted == true && !cubit.isClosed) await cubit.keepLocal(sid);
  }

  Future<void> _cancelSession(
      BuildContext context, DailyRosterCubit cubit) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('取消本日上課'),
                content: TextField(
                    controller: controller,
                    maxLength: 400,
                    decoration: const InputDecoration(
                        labelText: '原因（至少 3 字）',
                        helperText: '本日不列入出席率分母，既有紀錄會保留。')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('返回')),
                  ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => FilledButton(
                          onPressed: value.text.trim().length < 3
                              ? null
                              : () => Navigator.pop(context, value.text.trim()),
                          child: const Text('確認取消上課')))
                ]));
    // Dialog route finishes its closing animation before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (reason != null && !cubit.isClosed) {
      await cubit.setSession(SessionStatus.cancelled, reason: reason);
    }
  }
}
