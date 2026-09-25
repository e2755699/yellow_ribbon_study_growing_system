import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_attendance_info_cubit/daily_attendance_info_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/date_picker/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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
      child: YbLayout(
        scaffoldKey: scaffoldKey,
        title: '每日出席記錄',
        onBeforeExit: () async {
          return !_loading && await _dailyAttendanceCubit.saveBeforeExit();
        },
        showSaveConfirmation: _dailyAttendanceCubit.hasUnsavedChanges(),
        child: BlocBuilder<DailyAttendanceInfoCubit,
            StudentDailyAttendanceInfoState>(
          builder: (context, state) {
            return Column(
              children: [
                if (_loadError != null)
                  TextButton(
                      onPressed: _loadAttendanceData,
                      child: Text('$_loadError（重試）')),
                // 标题说明部分
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          FlutterFlowTheme.of(context).radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '管理學生每日出席狀態，包括出席、缺席、請假等情況',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .copyWith(
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                          ),
                        ),
                      ],
                    ),
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
                        final saved =
                            await _dailyAttendanceCubit.saveBeforeExit();
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
        ),
      ),
    );
  }

  Widget _mainSection(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return BlocBuilder<DailyAttendanceInfoCubit,
        StudentDailyAttendanceInfoState>(builder: (context, state) {
      var records = state.dailyAttendanceInfo.records;

      // 如果沒有記錄，顯示提示信息
      if (records.isEmpty) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                  FlutterFlowTheme.of(context).radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color:
                      FlutterFlowTheme.of(context).primaryText.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '沒有找到出席記錄',
                  style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '請嘗試選擇其他日期或班級地點',
                  style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              crossAxisSpacing: FlutterFlowTheme.of(context).spaceLarge,
              mainAxisSpacing: FlutterFlowTheme.of(context).spaceLarge,
              maxCrossAxisExtent: 560,
              mainAxisExtent: 230,
            ),
            itemCount: records.length,
            itemBuilder: (context, index) => AttendanceRecordCard(
                  records[index],
                  attendStatusNotifier: records[index].attendanceStatusNotifier,
                )),
      );
    });
  }
}

class AttendanceRecordCard extends StatelessWidget {
  final StudentDailyAttendanceRecord student;
  final ValueNotifier<AttendanceStatus> attendStatusNotifier;
  const AttendanceRecordCard(this.student,
      {super.key, required this.attendStatusNotifier});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AttendanceStatus>(
        valueListenable: attendStatusNotifier,
        builder: (context, status, _) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: status.color.withOpacity(0.4)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                  child: Text(student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600))),
              Checkbox(
                  value: status.isAttend,
                  onChanged: (checked) {
                    attendStatusNotifier.value = checked == true
                        ? AttendanceStatus.attend
                        : AttendanceStatus.absent;
                  }),
            ]),
            DropdownButtonFormField<AttendanceStatus>(
              isExpanded: true,
              value: status,
              decoration: const InputDecoration(
                  labelText: '出席狀態', border: OutlineInputBorder()),
              items: AttendanceStatus.values
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) attendStatusNotifier.value = value;
              },
            ),
            if (status == AttendanceStatus.leave)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextFormField(
                  initialValue: student.leaveReasonNotifier.value,
                  decoration: const InputDecoration(
                      labelText: '請假原因', border: OutlineInputBorder()),
                  onChanged: (value) =>
                      student.leaveReasonNotifier.value = value,
                ),
              ),
          ]),
        ),
      );
}

enum AttendanceStatus {
  attend("出席", Colors.green),
  absent("缺席", Colors.red),
  busAbsent("校車缺席", Colors.red),
  leave("請假", Colors.green),
  late("遲到", Colors.orange),
  earlyLeave("早退", Colors.orange);

  final String label;
  final Color color;

  const AttendanceStatus(this.label, this.color);

  factory AttendanceStatus.fromString(String statusStr) {
    //todo error handle
    return AttendanceStatus.values
        .where((status) => status.name == statusStr)
        .first;
  }

  get isAttend =>
      this == AttendanceStatus.attend ||
      this == AttendanceStatus.late ||
      this == AttendanceStatus.earlyLeave;
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
