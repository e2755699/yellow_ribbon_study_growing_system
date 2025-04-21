import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_performance_cubit/daily_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/yb_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/rating_scale/five_point_rating_scale.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/search_field/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_performance_page/student_performance_page_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class DailyPerformancePageWidget extends StatefulWidget {
  const DailyPerformancePageWidget({super.key});

  @override
  State<DailyPerformancePageWidget> createState() =>
      DailyPerformancePageWidgetState();
}

class DailyPerformancePageWidgetState extends State<DailyPerformancePageWidget>
    with YbToolbox {
  late HomePageModel _model;
  late DailyPerformanceCubit _dailyPerformanceCubit;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final DateTime date = DateTime.now();
  final ValueNotifier<ClassLocation> _classLocationFilterNotifier =
      ValueNotifier(ClassLocation.values.first);
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'dailyPerformancePage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();
    _classLocationFilterNotifier.addListener(() {
      _dailyPerformanceCubit.load(date, _classLocationFilterNotifier.value);
    });

    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });

    // 初始化 Cubit
    final studentsRepo = StudentsRepo();
    final dailyPerformanceRepo = DailyPerformanceRepo(studentsRepo);
    _dailyPerformanceCubit = DailyPerformanceCubit(
        StudentDailyPerformanceState(
            DailyPerformanceInfo(date, _classLocationFilterNotifier.value, [])),
        dailyPerformanceRepo)
      ..load(date, _classLocationFilterNotifier.value);
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dailyPerformanceCubit,
      child: Builder(builder: (context) {
        return YbLayout(
          scaffoldKey: scaffoldKey,
          title: HomeButton.dailyPerformance.name,
          child: Column(
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
                  const Gap(10),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DailyPerformanceCubit>().save();
                    },
                    child: text('儲存',
                        size: FlutterFlowTheme.of(context).textButtonSize),
                  ),
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
    return BlocBuilder<DailyPerformanceCubit, StudentDailyPerformanceState>(
        builder: (context, state) {
      var records = state.dailyPerformanceInfo.records;

      return ValueListenableBuilder<String>(
          valueListenable: _searchTextNotifier,
          builder: (context, searchText, _) {
            final filteredRecords = searchText.isEmpty
                ? records
                : records
                    .where((record) => record.name
                        .toLowerCase()
                        .contains(searchText.toLowerCase()))
                    .toList();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
                    mainAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
                    crossAxisCount: 2,
                    childAspectRatio: 1 / 1.5,
                  ),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) => _PerformanceBox(
                        filteredRecords[index],
                      )),
            );
          });
    });
  }
}

class _PerformanceBox extends StatelessWidget {
  final StudentDailyPerformanceRecord student;

  const _PerformanceBox(this.student);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: student.performanceRatingNotifier,
      builder: (context, performanceRating, _) => Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.all(
              Radius.circular(FlutterFlowTheme.of(context).radiusSmall)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 学生姓名和详情图标
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // 跳转到学生表现页面，并传递学生ID
                        context.pushNamed(
                          YbRoute.studentPerformanceDetail.name,
                          pathParameters: {'sid': student.sid},
                        );
                      },
                      child: Icon(
                        Icons.info_outline,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const Gap(8),

                // 保留原有的上課表現下拉選單
                Row(
                  children: [
                    const Text('上課表現：'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: YbDropdownMenu.fromList(
                        [
                          ...PerformanceRating.values.map((rating) =>
                              YbDropdownMenuOption(
                                  name: rating.label, value: rating)),
                        ],
                        initialSelection: YbDropdownMenuOption(
                            name: student.performanceRatingNotifier.value.label,
                            value: student.performanceRatingNotifier.value),
                        notifier: student.performanceRatingNotifier,
                      ),
                    ),
                  ],
                ),
                const Gap(8),

                // 五度量表評分 - 上課表現
                ValueListenableFivePointRatingScale(
                  ratingNotifier: student.classPerformanceRatingNotifier,
                  title: '上課表現',
                ),
                const Gap(8),

                // 五度量表評分 - 數學成績
                ValueListenableFivePointRatingScale(
                  ratingNotifier: student.mathPerformanceRatingNotifier,
                  title: '數學成績',
                ),
                const Gap(8),

                // 五度量表評分 - 國文成績
                ValueListenableFivePointRatingScale(
                  ratingNotifier: student.chinesePerformanceRatingNotifier,
                  title: '國文成績',
                ),
                const Gap(8),

                // 五度量表評分 - 英文成績
                ValueListenableFivePointRatingScale(
                  ratingNotifier: student.englishPerformanceRatingNotifier,
                  title: '英文成績',
                ),
                const Gap(8),

                // 五度量表評分 - 社會成績
                ValueListenableFivePointRatingScale(
                  ratingNotifier: student.socialPerformanceRatingNotifier,
                  title: '社會成績',
                ),
                const Gap(8),

                // 是否完成作业
                Row(
                  children: [
                    const Text('完成作業：'),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: student.homeworkCompletedNotifier,
                      builder: (context, homeworkCompleted, _) => Checkbox(
                        value: homeworkCompleted,
                        onChanged: (value) {
                          student.homeworkCompletedNotifier.value =
                              value ?? false;
                        },
                      ),
                    ),
                  ],
                ),

                // 是否小帮手
                Row(
                  children: [
                    const Text('小幫手：'),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: student.isHelperNotifier,
                      builder: (context, isHelper, _) => Checkbox(
                        value: isHelper,
                        onChanged: (value) {
                          student.isHelperNotifier.value = value ?? false;
                        },
                      ),
                    ),
                  ],
                ),

                // 表現描述（放在最下面）
                Row(
                  children: [
                    const Text('表現描述：'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: student.remarksNotifier,
                        builder: (context, remarks, _) => TextField(
                          decoration: const InputDecoration(
                            hintText: '請輸入表現描述',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          controller: TextEditingController(text: remarks),
                          onChanged: (value) {
                            student.remarksNotifier.value = value;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
