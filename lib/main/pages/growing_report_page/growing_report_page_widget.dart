import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/search_field/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/index.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class GrowingReportPageWidget extends StatefulWidget {
  const GrowingReportPageWidget({super.key});

  @override
  State<GrowingReportPageWidget> createState() =>
      GrowingReportPageWidgetState();
}

class GrowingReportPageWidgetState extends State<GrowingReportPageWidget>
    with YbToolbox {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<ClassLocation> _classLocationFilterNotifier =
      ValueNotifier(ClassLocation.values.first);

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'growingReportPage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();

    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    _searchTextNotifier.dispose();
    _classLocationFilterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SystemPage(
        scaffoldKey: scaffoldKey,
        title: HomeButton.growingReport.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tabSection(_classLocationFilterNotifier, operators: () {
              return [
                YbSearchField(
                  controller: _searchController,
                  hintText: '搜尋學生姓名...',
                  onChanged: (value) {
                    _searchTextNotifier.value = value;
                  },
                ),
              ];
            }),
            Gap(FlutterFlowTheme.of(context).spaceLarge),
            Expanded(
              child: BlocProvider(
                create: (context) => StudentsCubit(StudentsState([]))..load(),
                child: BlocBuilder<StudentsCubit, StudentsState>(
                    builder: (context, state) {
                  return ValueListenableBuilder(
                      valueListenable: _classLocationFilterNotifier,
                      builder: (context, filter, _) {
                        return ValueListenableBuilder<String>(
                            valueListenable: _searchTextNotifier,
                            builder: (context, searchText, _) {
                              var students = state.students
                                  .where((student) =>
                                      student.classLocation == filter.name)
                                  .toList();

                              if (searchText.isNotEmpty) {
                                students = students
                                    .where((student) => student.name
                                        .toLowerCase()
                                        .contains(searchText.toLowerCase()))
                                    .toList();
                              }

                              // 載入／錯誤／空結果各自有明確狀態，不再顯示空白格。
                              if (state.isLoading) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (state.errorMessage != null) {
                                return _ReportStatus(
                                    icon: Icons.cloud_off_rounded,
                                    message: state.errorMessage!,
                                    action: OutlinedButton(
                                        onPressed: () => context
                                            .read<StudentsCubit>()
                                            .load(),
                                        child: const Text('重新載入')));
                              }
                              if (students.isEmpty) {
                                return _ReportStatus(
                                    icon: Icons.person_search_rounded,
                                    message: searchText.isNotEmpty
                                        ? '找不到符合搜尋條件的學生'
                                        : '${filter.name}目前沒有學生，請切換其他據點。',
                                    action: searchText.isEmpty
                                        ? null
                                        : OutlinedButton(
                                            onPressed: _searchController.clear,
                                            child: const Text('清除搜尋')));
                              }

                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                  crossAxisSpacing:
                                      FlutterFlowTheme.of(context).spaceMedium,
                                  mainAxisSpacing:
                                      FlutterFlowTheme.of(context).spaceMedium,
                                  maxCrossAxisExtent: 900,
                                  mainAxisExtent: 104,
                                ),
                                itemCount: students.length,
                                itemBuilder: (context, index) {
                                  var student = students[index];
                                  return StudentGrowingReportCard(
                                      student: student);
                                },
                              );
                            });
                      });
                }),
              ),
            ),
          ],
        ));
  }
}

/// 名冊狀態：品牌淺色圓底插圖、說明與可選操作，與學生名冊的狀態呈現一致。
class _ReportStatus extends StatelessWidget {
  const _ReportStatus({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ds.metric('spaceMedium')),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: ds.brandTone(100), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: ds.brandTone(700))),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: ds.metric('bodySize'),
                  color: ds.color('secondaryText'))),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ]),
      ),
    );
  }
}
