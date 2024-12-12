import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/save_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import 'package:yellow_ribbon_study_growing_system/model/enum/home_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DailyAttendancePageWidget extends StatefulWidget {
  const DailyAttendancePageWidget({super.key});

  @override
  State<DailyAttendancePageWidget> createState() =>
      DailyAttendancePageWidgetState();
}

class DailyAttendancePageWidgetState extends State<DailyAttendancePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<StudentInfo> get students => [
        StudentInfo(1, "劉兆凌"),
        StudentInfo(2, "莊研安"),
        StudentInfo(3, "蔡文鐘"),
        StudentInfo(4, "蔡靜瑩"),
        StudentInfo(5, "黃彭漢"),
      ];

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
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
            color: FlutterFlowTheme.of(context).primaryText,
            onPressed: () {
              //todo 離開要save
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new)),
        backgroundColor: Colors.transparent, // 設置透明背景
        elevation: 0, // 去除陰影
        title: Center(
          child: _text("出缺勤紀錄",
              color: FlutterFlowTheme.of(context).primaryText, size: 20),
        ),
      ),
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Center(
              child: Container(
            color: FlutterFlowTheme.of(context).primaryBackground,
            child: Column(
              children: [
                _tabSection(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      child: GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 2 / 1,
                          ),
                          itemCount: students.length,
                          itemBuilder: (context, index) =>
                              AttendanceBox(students[index])),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }

  Text _text(String data, {Color? color, double? size}) {
    return Text(
      data,
      style: TextStyle(
        color: color,
        fontSize: 32,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _tabSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        YbDropdownMenu.fromList([
          YbDropdownMenuOption(name: "據點：台南永康區", value: 0),
          YbDropdownMenuOption(name: "據點：台南北區", value: 1),
          YbDropdownMenuOption(name: "據點：台南內門", value: 2),
        ], initialSelection: YbDropdownMenuOption(name: "台南永康區", value: 0)),
        SaveButton(),
      ],
    );
  }
}

class StudentInfo {
  final int id;
  final String name;

  StudentInfo(this.id, this.name);
}

class AttendanceBox extends StatelessWidget {
  final StudentInfo student;

  const AttendanceBox(this.student, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Checkbox(value: true, onChanged: (value) {}),
          Text(student.name),
          YbDropdownMenu.fromList([
            YbDropdownMenuOption(name: "出席", value: 1),
            YbDropdownMenuOption(name: "病假", value: 2),
            YbDropdownMenuOption(name: "缺席", value: 3),
          ])
        ],
      ),
    );
  }
}

class YbDropdownMenu<T> extends StatefulWidget {
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final DropdownMenuEntry<T> initialSelection;

  const YbDropdownMenu(
      {super.key,
      required this.dropdownMenuEntries,
      required this.initialSelection});

  factory YbDropdownMenu.fromList(List<YbDropdownMenuOption<T>> sources,
      {YbDropdownMenuOption<T>? initialSelection}) {
    var dropdownMenuEntries = UnmodifiableListView(sources.map(
        (YbDropdownMenuOption<T> source) =>
            DropdownMenuEntry<T>(value: source.value, label: source.name)));
    return YbDropdownMenu<T>(
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
  late T selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: DropdownMenu<T>(
        initialSelection: widget.initialSelection.value,
        onSelected: (T? newValue) {
          selectedValue = newValue!;
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
