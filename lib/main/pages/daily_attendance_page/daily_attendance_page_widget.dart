import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_attendance_info_cubit/student_daily_attendance_info_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
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
  late StudentDailyAttendanceInfoCubit _studentInfoCubit;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
      _studentInfoCubit.filter(_classLocationFilterNotifier.value);
    });
    _studentInfoCubit =
        StudentDailyAttendanceInfoCubit(StudentDailyAttendanceInfoState([]))
          ..load();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YbLayout(
      scaffoldKey: scaffoldKey,
      title: HomeButton.dailyAttendance.name,
      child: Column(
        children: [
          tabSection(_classLocationFilterNotifier),
          Expanded(
            child: _mainSection(context),
          ),
        ],
      ),
    );
  }

  Widget _mainSection(BuildContext context) {
    return BlocBuilder<StudentDailyAttendanceInfoCubit,
            StudentDailyAttendanceInfoState>(
        bloc: _studentInfoCubit,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
                  mainAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
                  crossAxisCount: 4,
                  childAspectRatio: 3 / 1,
                ),
                itemCount: state.students.length,
                itemBuilder: (context, index) => _AttendanceBox(
                      state.students[index],
                      attendStatusNotifier:
                          state.students[index].attendanceStatusNotifier,
                    )),
          );
        });
  }

}


class _AttendanceBox extends StatelessWidget {
  final StudentDailyAttendanceInfo student;
  final ValueNotifier<AttendanceStatus> attendStatusNotifier;

  const _AttendanceBox(this.student,
      {super.key, required this.attendStatusNotifier});

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
        child: Row(
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
                    YbDropdownMenuOption(name: status.name, value: status)),
              ],
              initialSelection: YbDropdownMenuOption(
                  name: attendStatusNotifier.value.name,
                  value: attendStatusNotifier.value),
              notifier: attendStatusNotifier,
            )
          ],
        ),
      ),
    );
  }
}

enum AttendanceStatus {
  attend("出席"),
  absent("缺席"),
  leave("請假");

  final String name;

  const AttendanceStatus(this.name);

  get isAttend => this == AttendanceStatus.attend;
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
    //todo 換選項時被rebuild了
    return Container(
      color: FlutterFlowTheme.of(context).primaryBackground,
      child: DropdownMenu<T>(
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
