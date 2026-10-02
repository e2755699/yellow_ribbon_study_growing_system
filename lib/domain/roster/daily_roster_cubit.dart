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
        drafts: drafts, rowErrors: {...state.rowErrors}..remove(sid)));
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
  Future<bool> _saveDrafts() async {
    if (!hasUnsavedChanges) return true;
    if (state.access?.enabled != true || state.roster == null) return false;
    final uid = _uid, scope = _scope, generation = _generation;
    emit(state.copy(saving: true, rowErrors: {}));
    var succeeded = 0;
    try {
      for (final sid in state.drafts.keys.toList()) {
        if (isClosed ||
            generation != _generation ||
            uid != _uid ||
            scope != _scope ||
            state.roster == null) {
          return false;
        }
        final draft = state.drafts[sid]!;
        final member =
            state.roster!.members.where((m) => m.student.id == sid).firstOrNull;
        if (member == null || member.enrollment.id != draft.enrollmentId) {
          emit(state
              .copy(rowErrors: {...state.rowErrors, sid: '就讀關係已變更，請核對或捨棄修改'}));
          continue;
        }
        final payload = draft.pending ??
            {
              'action': 'saveRecord',
              'operationId': const Uuid().v4(),
              'kind': kind,
              'studentId': sid,
              'locationId': state.locationId,
              'dateKey': state.date.value,
              'enrollmentId': draft.enrollmentId,
              'base': draft.base,
              'patch': draft.patch,
            };
        emit(state.copy(drafts: {
          ...state.drafts,
          sid: RecordDraft(draft.base, draft.patch,
              enrollmentId: draft.enrollmentId, pending: payload)
        }));
        if (!await persist()) return false;
        try {
          final result = await repository.command(payload);
          if (isClosed ||
              generation != _generation ||
              uid != _uid ||
              scope != _scope ||
              state.roster == null) {
            return false;
          }
          final latest = state.drafts[sid]!;
          final sentPatch = Map<String, dynamic>.from(payload['patch'] as Map);
          final confirmed = Map<String, dynamic>.from(result['values'] as Map);
          final remaining = <String, dynamic>{};
          for (final field in {...sentPatch.keys, ...latest.patch.keys}) {
            final desired = latest.patch.containsKey(field)
                ? latest.patch[field]
                : latest.base[field];
            if (!const DeepCollectionEquality()
                .equals(desired, confirmed[field])) {
              remaining[field] = desired;
            }
          }
          final drafts = {...state.drafts};
          if (remaining.isEmpty) {
            drafts.remove(sid);
          } else {
            drafts[sid] = RecordDraft(confirmed, remaining,
                enrollmentId: latest.enrollmentId);
          }
          final roster = state.roster!;
          final acknowledged = DailyRecord(kind,
              studentId: sid,
              locationId: state.locationId!,
              date: state.date,
              enrollmentId: latest.enrollmentId,
              nameSnapshot: member.student.name,
              values: confirmed,
              revision: result['revision'] as int,
              provenance: result['provenance'] as String? ?? 'confirmed',
              confirmedFields:
                  List<String>.from(result['confirmedFields'] as List? ?? []));
          _acknowledged[sid] = acknowledged;
          final rows = {..._records, sid: acknowledged};
          emit(state.copy(
              drafts: drafts,
              roster: DailyRoster(
                  date: roster.date,
                  locationId: roster.locationId,
                  members: roster.members,
                  attendance: kind == 'attendance' ? rows : roster.attendance,
                  performance:
                      kind == 'performance' ? rows : roster.performance,
                  fromCache: roster.fromCache,
                  session: roster.session)));
          succeeded++;
          await persist();
        } catch (error) {
          if (isClosed ||
              generation != _generation ||
              uid != _uid ||
              scope != _scope) {
            return false;
          }
          emit(state.copy(
              rowErrors: {...state.rowErrors, sid: '儲存未完成或資料衝突；請重試或採用雲端資料'}));
        }
      }
      if (isClosed) return false;
      emit(state.copy(
          saving: false,
          notice: '已儲存 $succeeded 筆，剩餘 ${state.drafts.length} 筆修改'));
      return !hasUnsavedChanges;
    } finally {
      if (!isClosed && uid == _uid) {
        emit(state.copy(
            saving: false, error: state.error, notice: state.notice));
      }
    }
  }

  Future<void> keepLocal(String sid) async {
    if (state.saving || state.drafts[sid] == null || state.roster == null) {
      return;
    }
    final draft = state.drafts[sid]!;
    final current = _records[sid]?.values ?? {};
    emit(state.copy(drafts: {
      ...state.drafts,
      sid: RecordDraft(Map.unmodifiable(current), draft.patch,
          enrollmentId: draft.enrollmentId)
    }, rowErrors: {...state.rowErrors}..remove(sid)));
    await persist();
  }

  Future<void> discard(String sid) async {
    if (state.saving) return;
    emit(state.copy(
        drafts: {...state.drafts}..remove(sid),
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
