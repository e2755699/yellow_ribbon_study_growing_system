import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/roster/monthly_attendance_report.dart';
import '../../model/roster/roster_models.dart';
import '../../repo/roster_repository.dart';
import '../../service/monthly_attendance_service.dart';
import '../../utils/subscription_failure.dart';

class MonthlyAttendanceState {
  const MonthlyAttendanceState(
      {required this.month,
      this.sites = const [],
      this.siteId,
      this.report,
      this.loading = true,
      this.error,
      this.exporting = false,
      this.exportError});
  final DateTime month;
  final List<ClassSite> sites;
  final String? siteId, error, exportError;
  final MonthlyAttendanceReport? report;
  final bool loading, exporting;
  bool get canExport =>
      !loading &&
      error == null &&
      !exporting &&
      report != null &&
      !report!.fromCache &&
      report!.rows.isNotEmpty;
}

class MonthlyAttendanceCubit extends Cubit<MonthlyAttendanceState> {
  MonthlyAttendanceCubit(this.repository, {DateTime? initialMonth})
      : super(MonthlyAttendanceState(month: initialMonth ?? previousMonth()));
  final RosterRepository repository;
  StreamSubscription<RosterAccess?>? _accessSub;
  StreamSubscription<List<ClassSite>>? _sitesSub;
  StreamSubscription<MonthlyAttendanceReport>? _reportSub;
  RosterAccess? _access;
  int _scope = 0, _revision = 0, _exportId = 0;
  static DateTime previousMonth() {
    final today = BusinessDate.today().calendar;
    return DateTime(today.year, today.month - 1);
  }

  void _set(
      {DateTime? month,
      List<ClassSite>? sites,
      String? siteId,
      MonthlyAttendanceReport? report,
      bool? loading,
      String? error,
      bool clearReport = false,
      bool clearError = false,
      bool? exporting,
      String? exportError}) {
    if (isClosed) return;
    emit(MonthlyAttendanceState(
        month: month ?? state.month,
        sites: sites ?? state.sites,
        siteId: siteId ?? state.siteId,
        report: clearReport ? null : report ?? state.report,
        loading: loading ?? state.loading,
        error: clearError ? null : error ?? state.error,
        exporting: exporting ?? state.exporting,
        exportError: exportError));
  }

  void start() {
    _accessSub = repository.watchAccess().listen((access) {
      if (isClosed) return;
      _access = access;
      _scope++;
      _revision++;
      _exportId++;
      _reportSub?.cancel();
      _reportSub = null;
      _set(
          sites: const [],
          clearReport: true,
          loading: access != null,
          error: access == null ? '尚未取得據點權限，請確認帳號已獲授權。' : null,
          clearError: access != null,
          exporting: false);
      if (access != null) _listenSites();
    }, onError: (Object error) => _fail(error));
  }

  void _listenSites() {
    _sitesSub?.cancel();
    final access = _access;
    if (access == null) return;
    _sitesSub = repository.watchSites().listen((sites) {
      if (isClosed || _access != access) return;
      final allowed =
          sites.where((s) => access.locationIds.contains(s.id)).toList();
      final previous = state.siteId;
      final selected = allowed.where((s) => s.id == previous).firstOrNull ??
          allowed.firstOrNull;
      _set(
          sites: allowed,
          siteId: selected?.id,
          loading: selected != null,
          clearError: true,
          clearReport: selected == null);
      if (selected == null) {
        _set(loading: false, error: '目前沒有可瀏覽的據點。');
      } else if (_reportSub == null || selected.id != previous) {
        _load(selected);
      } else {
        _set(loading: false);
      }
    }, onError: (Object error) => _fail(error));
  }

  void selectMonth(DateTime month) {
    if (month.year < 1900 || month.year > 9998) return;
    final normalized = DateTime(month.year, month.month);
    if (normalized == state.month) return;
    _set(month: normalized, clearReport: true, clearError: true);
    retry();
  }

  void selectSite(String? id) {
    final site = state.sites.where((site) => site.id == id).firstOrNull;
    if (site != null && site.id != state.siteId) _load(site);
  }

  void retry() {
    final site = state.sites.where((s) => s.id == state.siteId).firstOrNull;
    if (site != null) {
      _load(site);
    } else {
      _listenSites();
    }
  }

  void _load(ClassSite site) {
    final scope = ++_scope;
    _revision++;
    _exportId++;
    _reportSub?.cancel();
    _set(
        siteId: site.id,
        clearReport: true,
        loading: true,
        clearError: true,
        exporting: false);
    _reportSub = MonthlyAttendanceService(repository)
        .watch(state.month, site)
        .listen((report) {
      if (isClosed || scope != _scope || !_canRead(site.id)) return;
      _revision++;
      _set(report: report, loading: false, clearError: true);
    }, onError: (Object error) {
      if (!isClosed && scope == _scope) _fail(error);
    });
  }

  bool _canRead(String id) => _access?.locationIds.contains(id) == true;
  void _fail(Object error) {
    _revision++;
    _exportId++;
    final denied = clearsSubscriptionData(error);
    if (denied) {
      _scope++;
      _reportSub?.cancel();
      _reportSub = null;
    }
    _set(
        loading: false,
        exporting: false,
        clearReport: denied,
        error: denied ? '已失去資料存取權限，請重新登入或聯絡管理者。' : '報表讀取失敗，請檢查連線後重試。');
  }

  Future<void> download(
      Future<Uint8List> Function(MonthlyAttendanceReport) build,
      Future<void> Function(Uint8List, String) save) async {
    if (!state.canExport) return;
    final report = state.report!;
    final scope = _scope, revision = _revision, operation = ++_exportId;
    _set(exporting: true);
    try {
      final bytes = await build(report);
      if (isClosed ||
          scope != _scope ||
          operation != _exportId ||
          revision != _revision ||
          !_canRead(report.site.id) ||
          state.error != null ||
          state.report?.fromCache == true) {
        return;
      }
      await save(bytes, '${report.site.name}_${report.monthKey}_出席紀錄表.pdf');
    } catch (_) {
      if (!isClosed && operation == _exportId) {
        _set(exportError: 'PDF 產生失敗，請重試。');
      }
    } finally {
      if (!isClosed && operation == _exportId) {
        _set(exporting: false, exportError: state.exportError);
      }
    }
  }

  @override
  Future<void> close() async {
    _scope++;
    _revision++;
    _exportId++;
    await _accessSub?.cancel();
    await _sitesSub?.cancel();
    await _reportSub?.cancel();
    return super.close();
  }
}
