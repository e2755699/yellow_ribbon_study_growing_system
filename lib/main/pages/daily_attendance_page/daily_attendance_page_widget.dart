import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/attendance/attendance_record_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/attendance/attendance_summary_bar.dart';

// 既有呼叫端從本頁取得狀態列舉與點名卡；保留相容匯出。
export 'package:yellow_ribbon_study_growing_system/domain/enum/attendance_status.dart';
export 'package:yellow_ribbon_study_growing_system/main/components/attendance/attendance_record_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_attendance_info_cubit/daily_attendance_info_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/date_picker/index.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class DailyAttendancePageWidget extends StatefulWidget {
  const DailyAttendancePageWidget({super.key});

  @override
  State<DailyAttendancePageWidget> createState() =>
      DailyAttendancePageWidgetState();
}

class DailyAttendancePageWidgetState extends State<DailyAttendancePageWidget>
    with YbToolbox {
  late HomePageModel _model;
  late DailyAttendanceInfoCubit _dailyAttendanceCubit;
  bool _loading = false;
  bool _restoringFilter = false;
  String? _loadError;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // 日期選擇器狀態
  final ValueNotifier<DateTime> _selectedDateNotifier =
      ValueNotifier<DateTime>(DateTime.now());

  // 最早的記錄日期
  DateTime? _earliestDate;

  final ValueNotifier<ClassLocation> _classLocationFilterNotifier =
      ValueNotifier(ClassLocation.values.first);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'dailyAttendancePage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();

    _dailyAttendanceCubit = DailyAttendanceInfoCubit(
        StudentDailyAttendanceInfoState(DailyAttendanceInfo(
            _selectedDateNotifier.value,
            _classLocationFilterNotifier.value, [])));

    // 添加班級篩選監聽
    _classLocationFilterNotifier.addListener(() {
      _loadAttendanceData();
    });

    // 添加日期篩選監聽
    _selectedDateNotifier.addListener(() {
      _loadAttendanceData();
    });

    // 獲取最早日期並加載初始數據
    _initializeData();
  }

  // 初始化數據
  Future<void> _initializeData() async {
    // 獲取最早日期
    _earliestDate = await _dailyAttendanceCubit.getEarliestDate();
    if (!mounted) return;

    // 加載初始數據
    _loadAttendanceData();

    // 強制刷新UI
    if (mounted) setState(() {});
  }

  // 加載出席數據
  Future<void> _loadAttendanceData() async {
    if (_restoringFilter || !mounted) return;
    if (_loading) {
      _restoreFilters();
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _dailyAttendanceCubit.load(
          _selectedDateNotifier.value, _classLocationFilterNotifier.value);
      if (mounted) _restoreFilters();
    } catch (_) {
      if (mounted) {
        _restoreFilters();
        _loadError = '切換失敗，原有資料已保留；請檢查連線後重試';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _restoreFilters() {
    _restoringFilter = true;
    final info = _dailyAttendanceCubit.state.dailyAttendanceInfo;
    _selectedDateNotifier.value = info.date;
    _classLocationFilterNotifier.value = info.classLocation;
    _restoringFilter = false;
  }

  @override
  void dispose() {
    _model.dispose();
    _selectedDateNotifier.dispose();
    _classLocationFilterNotifier.dispose();
    _dailyAttendanceCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dailyAttendanceCubit,
      // 產品設計：返回時直接自動保存、不詢問。修改只留在本機草稿，離開或
      // 切換篩選時才寫入一次，避免每次點選狀態都寫 Firestore。保存失敗時
      // YbLayout 會留在原頁並提示，草稿不會遺失。
      child: SystemPage(
        scaffoldKey: scaffoldKey,
        title: '每日出席記錄',
        onBeforeExit: () async {
          return !_loading && await _dailyAttendanceCubit.saveBeforeExit();
        },
        showSaveConfirmation: false,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return BlocBuilder<DailyAttendanceInfoCubit,
        StudentDailyAttendanceInfoState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loadError != null)
              TextButton(
                  onPressed: _loadAttendanceData,
                  child: Text('$_loadError（重試）')),
            // 點名摘要：日期、據點與各狀態人數即時更新。
            // 左右邊距交給 SystemPage，摘要、篩選與卡片對齊同一基準線。
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AttendanceSummaryBar(
                records: state.dailyAttendanceInfo.records,
                dateLabel: DateFormat('yyyy/MM/dd')
                    .format(state.dailyAttendanceInfo.date),
                locationLabel: state.dailyAttendanceInfo.classLocation.name,
              ),
            ),
            tabSection(_classLocationFilterNotifier, operators: () {
              return [
                YbDatePicker(
                  selectedDate: _selectedDateNotifier.value,
                  onDateChanged: (newDate) {
                    _selectedDateNotifier.value = newDate;
                  },
                  labelText: '選擇日期',
                  firstDate: _earliestDate,
                  lastDate: DateTime.now(),
                ),
                // 主操作沿用 SystemTheme 主按鈕；原綠底白字對比不足 4.5:1。
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_loading) return;
                    final saved = await _dailyAttendanceCubit.saveBeforeExit();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(saved ? '已儲存' : '儲存失敗，請重試'),
                    ));
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('儲存'),
                ),
                // deleteButton(context, onPressed: (){
                //   context.read<DailyAttendanceInfoCubit>().delete();
                //   context.pop();
                // }),
              ];
            }),
            Expanded(
              child: _mainSection(context),
            ),
          ],
        );
      },
    );
  }

  Widget _mainSection(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return BlocBuilder<DailyAttendanceInfoCubit,
        StudentDailyAttendanceInfoState>(builder: (context, state) {
      var records = state.dailyAttendanceInfo.records;

      final ds = SystemTheme.of(context);
      final gap = ds.metric('spaceMedium');

      // 如果沒有記錄，顯示提示信息
      if (records.isEmpty) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: EdgeInsets.all(gap),
            padding: EdgeInsets.all(gap * 1.5),
            decoration: ds.cardDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 48, color: ds.color('secondaryText')),
                SizedBox(height: gap),
                Text('沒有找到出席記錄',
                    style: TextStyle(
                        fontSize: ds.metric('bodySize') + 2,
                        fontWeight: FontWeight.w700,
                        color: ds.color('primaryText'))),
                SizedBox(height: gap / 2),
                Text('請嘗試選擇其他日期或據點',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: ds.metric('bodySize'),
                        color: ds.color('secondaryText'))),
              ],
            ),
          ),
        );
      }

      // 卡片高度依內容（請假原因、放大文字）增長，不固定格高。
      return LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 3
            : width >= 640
                ? 2
                : 1;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final record in records)
                SizedBox(
                  width: cardWidth,
                  child: AttendanceRecordCard(record,
                      attendStatusNotifier: record.attendanceStatusNotifier),
                ),
            ],
          ),
        );
      });
    });
  }
}

class YbDropdownMenu<T> extends StatefulWidget {
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final DropdownMenuEntry<T> initialSelection;
  final ValueNotifier<T> notifier;

  const YbDropdownMenu(
      {super.key,
      required this.dropdownMenuEntries,
      required this.initialSelection,
      required this.notifier});

  factory YbDropdownMenu.fromList(List<YbDropdownMenuOption<T>> sources,
      {YbDropdownMenuOption<T>? initialSelection,
      required ValueNotifier<T> notifier}) {
    var dropdownMenuEntries = UnmodifiableListView(sources.map(
        (YbDropdownMenuOption<T> source) =>
            DropdownMenuEntry<T>(value: source.value, label: source.name)));
    return YbDropdownMenu<T>(
      notifier: notifier,
      dropdownMenuEntries: dropdownMenuEntries.toList(),
      initialSelection: DropdownMenuEntry(
          value: initialSelection?.value ?? sources.first.value,
          label: initialSelection?.name ?? sources.first.name),
    );
  }

  @override
  State<YbDropdownMenu> createState() => YbDropdownMenuState<T>();
}

class YbDropdownMenuState<T> extends State<YbDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    // 表面、文字與邊框都取自 SystemTheme；寫死白底會在 Dark 變成白字白底。
    final ds = SystemTheme.of(context);
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(ds.metric('radiusSmall')),
        borderSide: BorderSide(color: ds.color('border')));
    return DropdownMenu<T>(
      width: 220,
      initialSelection: widget.initialSelection.value,
      onSelected: (T? newValue) {
        widget.notifier.value = newValue!;
      },
      dropdownMenuEntries:
          widget.dropdownMenuEntries as List<DropdownMenuEntry<T>>,
      textStyle: TextStyle(
          fontSize: ds.metric('bodySize'), color: ds.color('primaryText')),
      trailingIcon: Icon(Icons.arrow_drop_down, color: ds.color('detail')),
      selectedTrailingIcon:
          Icon(Icons.arrow_drop_up, color: ds.color('detail')),
      menuStyle: MenuStyle(
        backgroundColor:
            WidgetStatePropertyAll(ds.color('secondaryBackground')),
        elevation: const WidgetStatePropertyAll(3),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ds.color('secondary'),
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: EdgeInsets.symmetric(
            horizontal: ds.metric('spaceMedium'),
            vertical: ds.metric('spaceSmall')),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
            borderSide: BorderSide(color: ds.primary, width: 2)),
      ),
    );
  }
}

class YbDropdownMenuOption<T> {
  String name;
  T value;

  YbDropdownMenuOption({required this.name, required this.value});
}
