import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/search_field/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/index.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page_header.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/class_location_filter_field.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
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
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return SystemPage(
        scaffoldKey: scaffoldKey,
        title: HomeButton.growingReport.name,
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
                        // 與學生名冊、每日頁相同：共用頁首＋資訊列，與名單一起捲動。
                        return CustomScrollView(slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: gap / 2),
                              child: SystemPageHeader(
                                title: '成長報告',
                                subtitle: '選擇學生，查看歷次表現與成長紀錄。',
                                filterFlex: const [1, 2],
                                filters: [
                                  ClassLocationFilterField(
                                      notifier: _classLocationFilterNotifier),
                                  YbSearchField(
                                    controller: _searchController,
                                    hintText: '搜尋學生姓名',
                                    width: double.infinity,
                                    onChanged: (value) {
                                      _searchTextNotifier.value = value;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                              child: SystemPageInfoBar(
                                  label: state.isLoading
                                      ? '正在載入學生資料…'
                                      : '${filter.name}  ·  ${students.length} 位學生')),
                          // 載入／錯誤／空結果各自有明確狀態，不再顯示空白格。
                          if (state.isLoading)
                            const SliverToBoxAdapter(
                                child: Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Center(
                                        child: CircularProgressIndicator())))
                          else if (state.errorMessage != null)
                            SliverToBoxAdapter(
                                child: _ReportStatus(
                                    icon: Icons.cloud_off_rounded,
                                    message: state.errorMessage!,
                                    action: OutlinedButton(
                                        onPressed: () => context
                                            .read<StudentsCubit>()
                                            .load(),
                                        child: const Text('重新載入'))))
                          else if (students.isEmpty)
                            SliverToBoxAdapter(
                                child: _ReportStatus(
                                    icon: Icons.person_search_rounded,
                                    message: searchText.isNotEmpty
                                        ? '找不到符合搜尋條件的學生'
                                        : '${filter.name}目前沒有學生，請切換其他據點。',
                                    action: searchText.isEmpty
                                        ? null
                                        : OutlinedButton(
                                            onPressed: _searchController.clear,
                                            child: const Text('清除搜尋'))))
                          else
                            SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                crossAxisSpacing: gap,
                                mainAxisSpacing: gap,
                                maxCrossAxisExtent: 900,
                                mainAxisExtent: 104,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                  (context, index) => StudentGrowingReportCard(
                                      student: students[index]),
                                  childCount: students.length),
                            ),
                          SliverToBoxAdapter(child: SizedBox(height: gap)),
                        ]);
                      });
                });
          }),
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
                  color: ds.surfaceTone(100), shape: BoxShape.circle),
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
