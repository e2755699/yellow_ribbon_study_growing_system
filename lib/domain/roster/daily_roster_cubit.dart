import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'daily_roster_service.dart';
import 'draft_store.dart';
import 'roster_models.dart';
import 'roster_repository.dart';
import 'roster_policy.dart';
import 'roster_command_failure.dart';
import '../service/record_merge.dart';

class RosterSaveFeedback {
  final String message;
  final bool incomplete;
  const RosterSaveFeedback(this.message, {required this.incomplete});
}

class RecordDraft {
  final Map<String, dynamic> base, patch;
  final Map<String, dynamic>? pending;
  final String? enrollmentId;
  RecordDraft(Map<String, dynamic> base, Map<String, dynamic> patch,
      {Map<String, dynamic>? pending, this.enrollmentId})
      : base = freezeRecordValue(base),
        patch = freezeRecordValue(patch),
        pending = pending == null ? null : freezeRecordValue(pending);
  Map<String, dynamic> toJson() => {
        'base': base,
        'patch': patch,
        'pending': pending,
        'enrollmentId': enrollmentId,
      };
  factory RecordDraft.fromJson(Map<String, dynamic> data) => RecordDraft(
      Map<String, dynamic>.unmodifiable(data['base'] as Map),
      Map<String, dynamic>.unmodifiable(data['patch'] as Map),
      pending: data['pending'] == null
          ? null
          : Map<String, dynamic>.unmodifiable(data['pending'] as Map),
      enrollmentId: data['enrollmentId'] as String?);
}

class DailyRosterState {
  final BusinessDate date;
  final String? locationId;
  final List<ClassSite> sites;
  final DailyRoster? roster;
  final RosterAccess? access;
  final String search, statusFilter;
  final bool loading, saving;
  final Map<String, RecordDraft> drafts;
  final Map<String, String> rowErrors;
  final Map<String, RosterCommandFailure> commandFailures;
  final RosterSaveFeedback? saveFeedback;
  final String? error, notice;
  const DailyRosterState(
      {required this.date,
      this.locationId,
      this.sites = const [],
      this.roster,
      this.access,
      this.search = '',
      this.statusFilter = 'all',
      this.loading = false,
      this.saving = false,
      this.drafts = const {},
      this.rowErrors = const {},
      this.commandFailures = const {},
      this.saveFeedback,
      this.error,
      this.notice});
  DailyRosterState copy(
          {BusinessDate? date,
          String? locationId,
          List<ClassSite>? sites,
          DailyRoster? roster,
          RosterAccess? access,
          String? search,
          String? statusFilter,
          bool? loading,
          bool? saving,
          Map<String, RecordDraft>? drafts,
          Map<String, String>? rowErrors,
          Map<String, RosterCommandFailure>? commandFailures,
          RosterSaveFeedback? saveFeedback,
          bool clearSaveFeedback = false,
          String? error,
          String? notice,
          bool clearRoster = false,
          bool clearAccess = false}) =>
      DailyRosterState(
          date: date ?? this.date,
          locationId: locationId ?? this.locationId,
          sites: sites ?? this.sites,
          roster: clearRoster ? null : roster ?? this.roster,
          access: clearAccess ? null : access ?? this.access,
          search: search ?? this.search,
          statusFilter: statusFilter ?? this.statusFilter,
          loading: loading ?? this.loading,
          saving: saving ?? this.saving,
          drafts: Map.unmodifiable(drafts ?? this.drafts),
          rowErrors: Map.unmodifiable(rowErrors ?? this.rowErrors),
          commandFailures:
              Map.unmodifiable(commandFailures ?? this.commandFailures),
          saveFeedback:
              clearSaveFeedback ? null : saveFeedback ?? this.saveFeedback,
          error: error,
          notice: notice);
}

class DailyRosterCubit extends Cubit<DailyRosterState> {
  final String kind;
  final DailyRosterService service;
  final DraftStore draftStore;
  StreamSubscription<DailyRoster>? _rosterSubscription;
  StreamSubscription<RosterAccess?>? _accessSubscription;
  StreamSubscription<List<ClassSite>>? _siteSubscription;
  String? _uid;
  int _generation = 0;
  Future<void> _persistQueue = Future.value();
  Future<bool>? _save;
  final Map<String, DailyRecord> _acknowledged = {};
  DailyRosterCubit(
      {required this.kind,
      required this.service,
      required this.draftStore,
      BusinessDate? date,
      String? initialLocationId})
      : super(DailyRosterState(
            date: date ?? BusinessDate.today(), locationId: initialLocationId));
  RosterRepository get repository => service.repository;
  String get _scope => [kind, state.date.value, state.locationId].join('|');
  bool get hasUnsavedChanges => state.drafts.isNotEmpty;
  bool get hasPendingSave => state.drafts.values.any((d) => d.pending != null);
  bool get canSave =>
      hasUnsavedChanges &&
      state.access != null &&
      state.roster != null &&
      !state.loading &&
      (state.access!.enabled || hasPendingSave);

  void start() {
    _accessSubscription ??= repository.watchAccess().listen((access) {
      if (isClosed) return;
      if (access == null) {
        _clearAccess('正在確認權限；若持續無法載入，請聯絡管理者開通據點');
      } else {
        final changedUser = _uid != access.uid;
        if (changedUser) _acknowledged.clear();
        _uid = access.uid;
        emit(state.copy(
            access: access,
            saving: changedUser ? false : null,
            drafts: changedUser ? {} : null,
            rowErrors: changedUser ? {} : null,
            commandFailures: changedUser ? {} : null,
            clearSaveFeedback: changedUser,
            error: access.enabled ? null : '資料維護中，暫時無法儲存'));
        if (state.locationId != null &&
            access.locationIds.contains(state.locationId)) {
          _subscribe(state.date, state.locationId!);
        }
      }
    }, onError: (Object error) {
      if (!isClosed) {
        _clearAccess('無法確認帳號權限，請重新登入');
      }
    });
    _siteSubscription ??= repository.watchSites().listen((sites) {
      if (isClosed) return;
      emit(state.copy(sites: sites, error: state.error, notice: state.notice));
      final available = sites.where((site) => site.active).toList();
      if (state.access != null &&
          available.isNotEmpty &&
          !available.any((site) => site.id == state.locationId)) {
        _subscribe(state.date, available.first.id);
      }
    }, onError: (Object error) {
      if (!isClosed) emit(state.copy(loading: false, error: '據點載入失敗，請重試'));
    });
  }

  void _clearAccess(String message) {
    // Capture the old user's draft before removing visible private state.
    unawaited(persist());
    _uid = null;
    _acknowledged.clear();
    _generation++;
    unawaited(_rosterSubscription?.cancel());
    _rosterSubscription = null;
    emit(state.copy(
        clearAccess: true,
        clearRoster: true,
        drafts: {},
        rowErrors: {},
        commandFailures: {},
        clearSaveFeedback: true,
        saving: false,
        loading: false,
        error: message));
  }

  Future<bool> open(BusinessDate date, String locationId) async {
    if (state.saving || (hasUnsavedChanges && !await saveBeforeExit())) {
      return false;
    }
    await _subscribe(date, locationId);
    return true;
  }

  Future<void> _subscribe(BusinessDate date, String locationId) async {
    final generation = ++_generation;
    await _rosterSubscription?.cancel();
    final uid = _uid;
    if (isClosed || uid == null || generation != _generation) return;
    final sameScope = state.date == date && state.locationId == locationId;
    if (!sameScope) _acknowledged.clear();
    emit(state.copy(
        date: date,
        locationId: locationId,
        clearRoster: true,
        loading: true,
        drafts: sameScope ? null : {},
        commandFailures: sameScope ? null : {},
        clearSaveFeedback: !sameScope,
        rowErrors: {}));
    try {
      final saved = await draftStore.read(uid, _scope);
      if (isClosed || generation != _generation) return;
      if (saved != null && state.drafts.isEmpty) {
        emit(state.copy(drafts: {
          for (final entry in saved.entries)
            entry.key: RecordDraft.fromJson(
                Map<String, dynamic>.from(entry.value as Map)),
        }, notice: '已恢復尚未儲存的修改，請核對後儲存'));
      }
      _rosterSubscription = service.watch(date, locationId).listen((roster) {
        if (isClosed || generation != _generation) return;
        final remote =
            kind == 'attendance' ? roster.attendance : roster.performance;
        _acknowledged.removeWhere(
            (sid, row) => (remote[sid]?.revision ?? 0) >= row.revision);
        final merged = {...remote, ..._acknowledged};
        emit(state.copy(
            roster: DailyRoster(
                date: roster.date,
                locationId: roster.locationId,
                members: roster.members,
                attendance: kind == 'attendance' ? merged : roster.attendance,
                performance:
                    kind == 'performance' ? merged : roster.performance,
                session: roster.session,
                fromCache: roster.fromCache),
            loading: false));
      }, onError: (Object error) {
        if (!isClosed && generation == _generation) {
          emit(state.copy(loading: false, error: '名冊尚未完整載入，請重試；修改已保留'));
        }
      });
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(state.copy(loading: false, error: '本機草稿無法讀取，請保留此頁並聯絡管理者'));
      }
    }
  }

  Map<String, DailyRecord> get _records => kind == 'attendance'
      ? state.roster?.attendance ?? {}
      : state.roster?.performance ?? {};
  Map<String, dynamic> values(String sid) =>
      {...?_records[sid]?.values, ...?state.drafts[sid]?.patch};
  List<RosterMember> get visibleMembers => (state.roster?.members ?? [])
      .where((member) =>
          member.student.name
              .toLowerCase()
              .contains(state.search.toLowerCase()) &&
          (state.statusFilter == 'all' ||
              (values(member.student.id)['status'] ?? 'unmarked') ==
                  state.statusFilter))
      .toList();
  void search(String text) =>
      emit(state.copy(search: text, error: state.error, notice: state.notice));
  void filterStatus(String value) => emit(state.copy(
      statusFilter: value, error: state.error, notice: state.notice));
  DailyRosterCounts get counts =>
      RosterPolicy.counts(state.roster?.members ?? [], values,
          kind: kind,
          confirmed: (sid, field) =>
              state.drafts[sid]?.patch.containsKey(field) == true ||
              _records[sid]?.fieldConfirmed(field) == true);
  bool canEdit(String sid) =>
      state.access?.enabled == true &&
      !state.loading &&
      state.error == null &&
      state.date.compareTo(BusinessDate.today()) <= 0 &&
      state.roster?.session?.status != SessionStatus.cancelled &&
      (state.roster?.members.any((member) => member.student.id == sid) ??
          false);

  void edit(String sid, String field, dynamic value) {
    if (!canEdit(sid)) return;
    final member =
        state.roster!.members.where((m) => m.student.id == sid).firstOrNull;
    if (member == null) return;
    final existing = state.drafts[sid];
    final base = existing?.base ?? _records[sid]?.values ?? {};
    final patch = {...?existing?.patch, field: value};
    if (field == 'status' && value != 'leave') patch['leaveReason'] = '';
    const equality = DeepCollectionEquality();
    patch.removeWhere((key, value) => equality.equals(base[key], value));
    final drafts = {...state.drafts};
    if (patch.isEmpty && existing?.pending == null) {
      drafts.remove(sid);
    } else {
      drafts[sid] = RecordDraft(Map.unmodifiable(base), Map.unmodifiable(patch),
          pending: existing?.pending,
          enrollmentId: existing?.enrollmentId ?? member.enrollment.id);
    }
    emit(state.copy(
        drafts: drafts,
        clearSaveFeedback: true,
        rowErrors: {...state.rowErrors}..remove(sid)));
    persist();
  }

  void confirm(String sid) {
    if (!canEdit(sid) || state.saving) return;
    final member = state.roster!.members.firstWhere((m) => m.student.id == sid);
    final current = values(sid);
    final fields = kind == 'attendance'
        ? ['status', 'leaveReason']
        : [
            'performanceRating',
            'remarks',
            'excellentCharacters',
            'classPerformanceRating',
            'mathPerformanceRating',
            'chinesePerformanceRating',
            'englishPerformanceRating',
            'socialPerformanceRating'
          ];
    final patch = {
      for (final key in fields)
        if (current.containsKey(key)) key: current[key]
    };
    if (patch.isEmpty) return;
    emit(state.copy(drafts: {
      ...state.drafts,
      sid: RecordDraft(
          state.drafts[sid]?.base ?? _records[sid]?.values ?? {}, patch,
          enrollmentId: member.enrollment.id,
          pending: state.drafts[sid]?.pending)
    }));
    persist();
  }

  Future<bool> persist() {
    final uid = _uid;
    if (uid == null || state.locationId == null) return Future.value(true);
    final scope = _scope;
    final snapshot = jsonDecode(jsonEncode({
      for (final entry in state.drafts.entries) entry.key: entry.value.toJson(),
    })) as Map<String, dynamic>;
    final write = _persistQueue.then((_) =>
        draftStore.write(uid, scope, snapshot.isEmpty ? null : snapshot));
    _persistQueue = write.catchError((Object error) {
      if (!isClosed && uid == _uid && scope == _scope) {
        emit(state.copy(error: '草稿未能保存到本機，請保持 App 開啟並重試'));
      }
    });
    return write.then((_) => true, onError: (Object error) => false);
  }

  Future<bool> saveBeforeExit() =>
      _save ??= _saveDrafts().whenComplete(() => _save = null);
  void _acceptRecords(
      List<Map<String, dynamic>> submitted, Map<String, dynamic> result) {
    final results = Map<String, dynamic>.from(result['records'] as Map);
    // Validate every acknowledgment before clearing any draft. A truncated
    // response is ambiguous even if the server committed the entire batch.
    final acknowledged = <String, DailyRecord>{};
    for (final row in submitted) {
      final sid = row['studentId'] as String;
      final response = Map<String, dynamic>.from(results[sid] as Map);
      final values = Map<String, dynamic>.from(response['values'] as Map);
      final revision = response['revision'] as int;
      if (revision < 1) throw const FormatException('Invalid revision');
      acknowledged[sid] = DailyRecord(kind,
          studentId: sid,
          locationId: state.locationId!,
          date: state.date,
          enrollmentId: row['enrollmentId'] as String?,
          nameSnapshot: state.roster!.members
                  .where((m) => m.student.id == sid)
                  .firstOrNull
                  ?.student
                  .name ??
              '',
          values: values,
          revision: revision,
          provenance: response['provenance'] as String? ?? 'confirmed',
          confirmedFields:
              List<String>.from(response['confirmedFields'] as List? ?? []));
    }
    final nextDrafts = {...state.drafts};
    final rows = {..._records};
    for (final row in submitted) {
      final sid = row['studentId'] as String;
      final latest = nextDrafts[sid]!;
      final saved = acknowledged[sid]!;
      final sentPatch = Map<String, dynamic>.from(row['patch'] as Map);
      final remaining = <String, dynamic>{};
      for (final field in {...sentPatch.keys, ...latest.patch.keys}) {
        final desired = latest.patch.containsKey(field)
            ? latest.patch[field]
            : latest.base[field];
        if (!const DeepCollectionEquality()
            .equals(desired, saved.values[field])) {
          remaining[field] = desired;
        }
      }
      if (remaining.isEmpty) {
        nextDrafts.remove(sid);
      } else {
        nextDrafts[sid] = RecordDraft(saved.values, remaining,
            enrollmentId: latest.enrollmentId);
      }
      // Recovering an old receipt must never regress a newer subscription.
      if ((rows[sid]?.revision ?? 0) < saved.revision) {
        _acknowledged[sid] = saved;
        rows[sid] = saved;
      }
    }
    final roster = state.roster!;
    emit(state.copy(
        drafts: nextDrafts,
        roster: DailyRoster(
            date: roster.date,
            locationId: roster.locationId,
            members: roster.members,
            attendance: kind == 'attendance' ? rows : roster.attendance,
            performance: kind == 'performance' ? rows : roster.performance,
            fromCache: roster.fromCache,
            session: roster.session)));
  }

  Future<bool> _saveDrafts() async {
    if (!hasUnsavedChanges) return true;
    if (state.drafts.values.any((d) => d.pending?['action'] == 'saveRecord')) {
      if (!await _recoverLegacyDrafts()) return false;
      if (!hasUnsavedChanges) return true;
    }
    if (!canSave) {
      emit(state.copy(
          saveFeedback: const RosterSaveFeedback(
              '儲存未開始：尚未確認名冊或操作權限。修改仍保留，請重新載入後重試。',
              incomplete: true),
          error: state.error));
      return false;
    }
    final uid = _uid, scope = _scope, generation = _generation;
    bool current() =>
        !isClosed &&
        generation == _generation &&
        uid == _uid &&
        scope == _scope &&
        state.roster != null;
    var confirmedCount = 0;
    var started = false;
    var recovering = false;
    Map<String, dynamic>? payload;
    List<Map<String, dynamic>> submitted = [];
    emit(state.copy(
        saving: true,
        rowErrors: {},
        commandFailures: {},
        clearSaveFeedback: true));
    try {
      final pending = state.drafts.values
          .map((d) => d.pending)
          .whereType<Map<String, dynamic>>()
          .toList();
      recovering = pending.isNotEmpty;
      if (recovering) {
        // Store the full batch on the first row; other rows reference its ID.
        // This avoids duplicating large notes once per student in local storage.
        payload = pending
            .where((p) => p['action'] == 'saveRecords' && p['records'] is List)
            .firstOrNull;
        if (payload == null ||
            pending.any((p) => p['operationId'] != payload!['operationId'])) {
          emit(state.copy(error: '有舊版或不完整的待確認儲存，請保留草稿並聯絡管理者核對原交易。'));
          return false;
        }
      } else {
        final invalid = <String, String>{};
        for (final entry in state.drafts.entries) {
          final member = state.roster!.members
              .where((m) => m.student.id == entry.key)
              .firstOrNull;
          if (member == null ||
              member.enrollment.id != entry.value.enrollmentId) {
            invalid[entry.key] = '整批儲存未開始：就讀關係已變更，請核對；所有修改仍保留';
          }
        }
        if (invalid.isNotEmpty) {
          emit(state.copy(rowErrors: invalid));
          return false;
        }
        payload = {
          'action': 'saveRecords',
          'operationId': const Uuid().v4(),
          'kind': kind,
          'locationId': state.locationId,
          'dateKey': state.date.value,
          'records': [
            for (final entry in state.drafts.entries)
              {
                'studentId': entry.key,
                'enrollmentId': entry.value.enrollmentId,
                'base': entry.value.base,
                'patch': entry.value.patch,
              }
          ],
        };
      }
      final command = freezeRecordValue(payload);
      submitted = (command['records'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      if (submitted.isEmpty ||
          submitted.any((r) => !state.drafts.containsKey(r['studentId']))) {
        emit(state.copy(error: '待確認儲存與本機草稿不一致，請保留此頁並聯絡管理者。'));
        return false;
      }
      final drafts = {...state.drafts};
      for (var i = 0; i < submitted.length; i++) {
        final sid = submitted[i]['studentId'] as String;
        final draft = drafts[sid]!;
        drafts[sid] = RecordDraft(draft.base, draft.patch,
            enrollmentId: draft.enrollmentId,
            pending: i == 0
                ? command
                : {
                    'action': 'saveRecords',
                    'operationId': command['operationId'],
                  });
      }
      emit(state.copy(drafts: drafts));
      if (!await persist() || !current()) return false;
      started = true;
      final result = await repository.command(command);
      if (!current()) return false;
      _acceptRecords(submitted, result);
      confirmedCount = submitted.length;
      if (!await persist()) return false;
      return !hasUnsavedChanges;
    } catch (error) {
      if (!current()) return false;
      final classified = error is RosterCommandFailure
          ? error
          : RosterCommandFailure(
              error is RecordConflict ? 'aborted' : 'unknown');
      final failure = recovering && !classified.outcomeUnknown
          ? RosterCommandFailure(classified.code, previousOutcomeUnknown: true)
          : classified;
      final drafts = {...state.drafts};
      for (final row in submitted) {
        final sid = row['studentId'] as String;
        final latest = drafts[sid];
        if (!failure.outcomeUnknown && latest != null) {
          drafts[sid] = RecordDraft(latest.base, latest.patch,
              enrollmentId: latest.enrollmentId);
        }
      }
      emit(state.copy(drafts: drafts, commandFailures: {
        for (final row in submitted) row['studentId'] as String: failure,
      }, rowErrors: {
        for (final row in submitted)
          row['studentId'] as String: failure.message,
      }));
      await persist();
      return false;
    } finally {
      if (current()) {
        final incomplete = hasUnsavedChanges || state.error != null;
        final unknown =
            state.commandFailures.values.any((f) => f.outcomeUnknown);
        final names = {
          for (final member in state.roster!.members)
            member.student.id: member.student.name,
        };
        final message = [
          if (confirmedCount > 0) '整批儲存成功：已確認儲存 $confirmedCount 筆修改。',
          if (confirmedCount == 0 && unknown) '整批儲存結果尚未確認；所有修改仍保留，請重試確認同一筆交易。',
          if (confirmedCount == 0 && !unknown)
            started ? '整批儲存失敗：所有修改仍保留。' : '整批儲存未開始：所有修改仍保留。',
          for (final entry in state.rowErrors.entries)
            '${names[entry.key] ?? "待核對學生"}：${entry.value}',
          if (state.error != null) state.error!,
          if (confirmedCount > 0 && hasUnsavedChanges)
            '儲存期間又有新修改尚未提交，請再次按「儲存修改」。',
        ].join('\n');
        emit(state.copy(
            saving: false,
            error: state.error,
            notice: state.notice,
            saveFeedback: RosterSaveFeedback(message, incomplete: incomplete)));
      }
    }
  }

  /// Upgrade recovery reads old receipts only; it must not replay a potentially
  /// committed pre-upgrade single-row write as part of a new batch.
  Future<bool> _recoverLegacyDrafts() async {
    final uid = _uid, scope = _scope, generation = _generation;
    bool current() =>
        !isClosed &&
        uid == _uid &&
        scope == _scope &&
        generation == _generation &&
        state.roster != null;
    if (!current()) return false;
    final originals = {
      for (final entry in state.drafts.entries)
        if (entry.value.pending?['action'] == 'saveRecord')
          entry.key: entry.value.pending!,
    };
    emit(state.copy(
        saving: true,
        rowErrors: {},
        commandFailures: {},
        clearSaveFeedback: true));
    var recovered = 0;
    try {
      for (final entry in originals.entries) {
        try {
          final result = await repository.command({
            'action': 'recoverOperation',
            'original': entry.value,
          });
          if (!current()) return false;
          _acceptRecords([
            entry.value
          ], {
            'records': {entry.key: result}
          });
          recovered++;
          if (!await persist()) return false;
        } catch (error) {
          if (!current()) return false;
          final failure = RosterCommandFailure(
              error is RosterCommandFailure ? error.code : 'unknown',
              previousOutcomeUnknown: true);
          emit(state.copy(
              commandFailures: {entry.key: failure},
              rowErrors: {entry.key: failure.message}));
          return false;
        }
      }
      return true;
    } finally {
      if (current()) {
        emit(state.copy(
            saving: false,
            error: state.error,
            saveFeedback: RosterSaveFeedback(
                [
                  '已核對舊版儲存 $recovered 筆。',
                  ...state.rowErrors.values,
                  if (state.error != null) state.error!,
                  if (state.rowErrors.isEmpty && hasUnsavedChanges)
                    '尚有修改待整批儲存。',
                ].join('\n'),
                incomplete: hasUnsavedChanges || state.error != null)));
      }
    }
  }

  Future<void> keepLocal(String sid) async {
    if (state.saving ||
        state.drafts[sid] == null ||
        state.roster == null ||
        state.commandFailures[sid]?.conflict != true) {
      return;
    }
    final draft = state.drafts[sid]!;
    final current = _records[sid]?.values ?? {};
    emit(state.copy(
        drafts: {
          ...state.drafts,
          sid: RecordDraft(Map.unmodifiable(current), draft.patch,
              enrollmentId: draft.enrollmentId)
        },
        clearSaveFeedback: true,
        commandFailures: {...state.commandFailures}..remove(sid),
        rowErrors: {...state.rowErrors}..remove(sid)));
    await persist();
  }

  Future<void> discard(String sid) async {
    if (state.saving || state.drafts[sid]?.pending != null) return;
    emit(state.copy(
        drafts: {...state.drafts}..remove(sid),
        clearSaveFeedback: true,
        commandFailures: {...state.commandFailures}..remove(sid),
        rowErrors: {...state.rowErrors}..remove(sid)));
    await persist();
  }

  Future<void> retry() async {
    if (state.locationId != null) {
      await _subscribe(state.date, state.locationId!);
    }
  }

  bool get canSetSession =>
      !state.saving &&
      state.access?.enabled == true &&
      state.roster != null &&
      state.date.compareTo(BusinessDate.today()) <= 0;
  Future<bool> setSession(SessionStatus status, {String reason = ''}) async {
    if (!canSetSession ||
        (status == SessionStatus.cancelled &&
            state.access?.isManager != true)) {
      return false;
    }
    if (hasUnsavedChanges && !await saveBeforeExit()) return false;
    final uid = _uid, scope = _scope;
    final roster = state.roster!;
    emit(state.copy(saving: true));
    try {
      final result = await repository.command({
        'action': 'setSession',
        'operationId': const Uuid().v4(),
        'locationId': state.locationId,
        'dateKey': state.date.value,
        'status': status.name,
        'reason': reason,
        'expectedRevision': roster.session?.revision ?? 0,
      });
      if (isClosed || uid != _uid || scope != _scope) return false;
      final current = state.roster ?? roster;
      emit(state.copy(
          saving: false,
          roster: DailyRoster(
              date: current.date,
              locationId: current.locationId,
              members: current.members,
              attendance: current.attendance,
              performance: current.performance,
              fromCache: current.fromCache,
              session: ClassSession(current.locationId, current.date, status,
                  revision: result['revision'] as int)),
          notice: status == SessionStatus.held ? '已確認本日有上課' : '已取消本日上課，紀錄仍保留'));
      return true;
    } catch (_) {
      if (!isClosed && uid == _uid && scope == _scope) {
        emit(state.copy(saving: false, error: '課次尚未更新，請核對雲端狀態後重試'));
      }
      return false;
    }
  }

  @override
  Future<void> close() async {
    _generation++;
    await persist();
    await _rosterSubscription?.cancel();
    await _accessSubscription?.cancel();
    await _siteSubscription?.cancel();
    await super.close();
  }
}
