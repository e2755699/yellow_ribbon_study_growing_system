import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_attendance_info_cubit/daily_attendance_info_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/yb_button.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final DateTime date = DateTime.now();
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
    _classLocationFilterNotifier.addListener(() {
      _dailyAttendanceCubit.load(date, _classLocationFilterNotifier.value);
    });
    _dailyAttendanceCubit = DailyAttendanceInfoCubit(
        StudentDailyAttendanceInfoState(
            DailyAttendanceInfo(date, _classLocationFilterNotifier.value, [])))
      ..load(date, _classLocationFilterNotifier.value);
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dailyAttendanceCubit,
      child: Builder(builder: (context) {
        return YbLayout(
          scaffoldKey: scaffoldKey,
          title: HomeButton.dailyAttendance.name,
          child: Column(
            children: [
              tabSection(_classLocationFilterNotifier, operators: () {
                return [
                  ElevatedButton(
                    onPressed: () {
                      //todo 離開或切filter應該要問user是否儲存
                      context.read<DailyAttendanceInfoCubit>().save();
                    },
                    child: text('儲存',
                        size: FlutterFlowTheme.of(context).textButtonSize),
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
          ),
        );
      }),
    );
  }

  Widget _mainSection(BuildContext context) {
    return BlocBuilder<DailyAttendanceInfoCubit,
        StudentDailyAttendanceInfoState>(builder: (context, state) {
      var records = state.dailyAttendanceInfo.records;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
              mainAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
              crossAxisCount: 4,
              childAspectRatio: 2 / 1,
            ),
            itemCount: records.length,
            itemBuilder: (context, index) => _AttendanceBox(
                  records[index],
                  attendStatusNotifier: records[index].attendanceStatusNotifier,
                )),
      );
    });
  }
}

class _AttendanceBox extends StatelessWidget {
  final StudentDailyAttendanceRecord student;
  final ValueNotifier<AttendanceStatus> attendStatusNotifier;

  const _AttendanceBox(this.student,
      {required this.attendStatusNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: attendStatusNotifier,
      builder: (context, attendStatus, _) => Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.all(
              Radius.circular(FlutterFlowTheme.of(context).radiusSmall)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Checkbox(
                      value: attendStatus.isAttend,
                      onChanged: (isChecked) {
                        if (isChecked ?? false) {
                          attendStatusNotifier.value = AttendanceStatus.attend;
                        }
                      }),
                  Text(student.name),
                  Gap(FlutterFlowTheme.of(context).spaceMedium),
                  YbDropdownMenu.fromList(
                    [
                      ...AttendanceStatus.values.map((status) =>
                          YbDropdownMenuOption(name: status.label, value: status)),
                    ],
                    initialSelection: YbDropdownMenuOption(
                        name: attendStatusNotifier.value.label,
                        value: attendStatusNotifier.value),
                    notifier: attendStatusNotifier,
                  )
                ],
              ),
              if (attendStatus == AttendanceStatus.leave || 
                  attendStatus == AttendanceStatus.late || 
                  attendStatus == AttendanceStatus.earlyLeave ||
                  attendStatus == AttendanceStatus.busAbsent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ValueListenableBuilder(
                    valueListenable: student.leaveReasonNotifier,
                    builder: (context, leaveReason, _) => TextField(
                      decoration: const InputDecoration(
                        hintText: '請輸入原因',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      ),
                      controller: TextEditingController(text: leaveReason),
                      onChanged: (value) {
                        student.leaveReasonNotifier.value = value;
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AttendanceStatus {
  attend("出席"),
  absent("缺席"),
  leave("請假"),
  late("遲到"),
  earlyLeave("早退"),
  busAbsent("校車缺席");

  final String label;

  const AttendanceStatus(this.label);

  factory AttendanceStatus.fromString(String statusStr) {
    //todo error handle
    return AttendanceStatus.values
        .where((status) => status.name == statusStr)
        .first;
  }

  get isAttend => this == AttendanceStatus.attend || 
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
  State<YbDropdownMenu> createState() => _YbDropdownMenuState();
}

class _YbDropdownMenuState<T> extends State<YbDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: FlutterFlowTheme.of(context).primaryBackground,
      width: 200,
      child: DropdownMenu<T>(
        width: 200,
        initialSelection: widget.initialSelection.value,
        onSelected: (T? newValue) {
          widget.notifier.value = newValue!;
        },
        dropdownMenuEntries:
            widget.dropdownMenuEntries as List<DropdownMenuEntry<T>>,
      ),
    );
  }
}

class YbDropdownMenuOption<T> {
  String name;
  T value;

  YbDropdownMenuOption({required this.name, required this.value});
}
