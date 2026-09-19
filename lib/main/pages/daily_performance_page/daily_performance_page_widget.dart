import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_performance_cubit/daily_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/character_tag/character_tag_selector.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/rating_scale/five_point_rating_scale.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/search_field/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
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
  bool _loading = false;
  bool _restoringFilter = false;
  String? _loadError;

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
      _loadPerformanceData();
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
        dailyPerformanceRepo);
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    if (_restoringFilter || !mounted) return;
    if (_loading) {
      _restoreFilter();
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _dailyPerformanceCubit.load(
          date, _classLocationFilterNotifier.value);
      if (mounted) _restoreFilter();
    } catch (_) {
      if (mounted) {
        _restoreFilter();
        _loadError = '切換失敗，原有資料已保留；請檢查連線後重試';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _restoreFilter() {
    _restoringFilter = true;
    _classLocationFilterNotifier.value =
        _dailyPerformanceCubit.state.dailyPerformanceInfo.classLocation;
    _restoringFilter = false;
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    _classLocationFilterNotifier.dispose();
    _searchTextNotifier.dispose();
    _dailyPerformanceCubit.close();
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
          onBeforeExit: () async {
            return !_loading && await _dailyPerformanceCubit.saveBeforeExit();
          },
          showSaveConfirmation:
              context.read<DailyPerformanceCubit>().hasUnsavedChanges(),
          child: Column(
            children: [
              if (_loadError != null)
                TextButton(
                    onPressed: _loadPerformanceData,
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
                          '記錄學生每日的學習表現，包括五度量表評分、作業完成情況、小幫手等',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.copyWith(
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: YbSearchField(
                      controller: _searchController,
                      hintText: '搜尋學生姓名...',
                      onChanged: (value) {
                        _searchTextNotifier.value = value;
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_loading) return;
                      final saved = await context
                          .read<DailyPerformanceCubit>()
                          .saveBeforeExit();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(saved ? '資料已儲存' : '儲存失敗，請重試')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '儲存',
                          style:
                              FlutterFlowTheme.of(context).titleSmall.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
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

            // 如果沒有記錄，顯示提示信息
            if (filteredRecords.isEmpty) {
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
                        color: FlutterFlowTheme.of(context)
                            .primaryText
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '沒有找到表現記錄',
                        style:
                            FlutterFlowTheme.of(context).titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '請嘗試選擇其他班級地點或清除搜尋條件',
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
              child: LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000 ? 2 : 1;
                return ListView.separated(
                  itemCount: (filteredRecords.length + columns - 1) ~/ columns,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, row) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var column = 0; column < columns; column++) ...[
                          if (column > 0) const SizedBox(width: 20),
                          Expanded(
                              child: row * columns + column <
                                      filteredRecords.length
                                  ? DailyPerformanceRecordCard(
                                      filteredRecords[row * columns + column])
                                  : const SizedBox()),
                        ],
                      ]),
                );
              }),
            );
          });
    });
  }
}

class DailyPerformanceRecordCard extends StatelessWidget {
  final StudentDailyPerformanceRecord student;

  const DailyPerformanceRecordCard(this.student, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: student.classPerformanceRatingNotifier,
      builder: (context, classPerformanceRating, _) {
        // 根據上課表現評分獲取顏色
        final performanceColor = _getRatingColor(classPerformanceRating);

        return Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 5,
                spreadRadius: 0,
              )
            ],
            borderRadius: BorderRadius.all(
                Radius.circular(FlutterFlowTheme.of(context).radiusMedium)),
            border: Border.all(
              color: performanceColor.withOpacity(0.3),
              width: 2,
            ),
          ),
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
                        child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: performanceColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: performanceColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Flexible(
                              child: Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          )),
                        ],
                      ),
                    )),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        onPressed: () {
                          // 跳转到学生表现页面，并传递学生ID
                          context.pushNamed(
                            YbRoute.studentPerformanceDetail.name,
                            pathParameters: {'sid': student.sid},
                          );
                        },
                        icon: Icon(
                          Icons.info_outline,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 顯示已選擇的優秀品格標籤
                ValueListenableBuilder(
                  valueListenable: student.excellentCharactersNotifier,
                  builder: (context, excellentCharacters, _) {
                    // 分離普通標籤和特殊標籤
                    final regularTags = excellentCharacters
                        .where((tag) => !tag.isSpecialTag)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: FlutterFlowTheme.of(context).warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '優秀品格與表現',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 優秀品格標籤選擇器（包含特殊標籤）
                        CharacterTagSelector(
                          selectedTags: excellentCharacters,
                          availableTags: ExcellentCharacter.values,
                          onTagsChanged: (updatedTags) {
                            student.excellentCharactersNotifier.value =
                                updatedTags;
                          },
                          showSpecialTags: true,
                        ),

                        // 只有當有普通品格標籤時才顯示
                        if (regularTags.isNotEmpty) const SizedBox(height: 8),
                        if (regularTags.isNotEmpty)
                          CharacterTagsDisplay(
                            tags: regularTags,
                          ),

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // 五度量表評分區域
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '課程表現評分',
                        style: FlutterFlowTheme.of(context).titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
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
                        ratingNotifier:
                            student.chinesePerformanceRatingNotifier,
                        title: '國文成績',
                      ),
                      const Gap(8),

                      // 五度量表評分 - 英文成績
                      ValueListenableFivePointRatingScale(
                        ratingNotifier:
                            student.englishPerformanceRatingNotifier,
                        title: '英文成績',
                      ),
                      const Gap(8),

                      // 五度量表評分 - 社會成績
                      ValueListenableFivePointRatingScale(
                        ratingNotifier: student.socialPerformanceRatingNotifier,
                        title: '社會成績',
                      ),
                    ],
                  ),
                ),

                // 表現描述區域
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '表現描述',
                        style: FlutterFlowTheme.of(context).titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      ValueListenableBuilder(
                        valueListenable: student.remarksNotifier,
                        builder: (context, remarks, _) => TextFormField(
                          key: ValueKey('${student.sid}-${student.recordDate}'),
                          initialValue: remarks,
                          decoration: InputDecoration(
                            hintText: '請輸入表現描述',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 10.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: performanceColor,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            student.remarksNotifier.value = value;
                          },
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 根據評分等級獲取顏色
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
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
