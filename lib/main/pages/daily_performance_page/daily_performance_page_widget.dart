import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page_header.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/class_location_filter_field.dart';
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
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
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
      // 產品設計：返回時直接自動保存、不詢問（見每日出席頁說明），
      // 以離開／切換篩選時的單次寫入取代逐次寫入。
      child: Builder(builder: (context) {
        return SystemPage(
          scaffoldKey: scaffoldKey,
          title: HomeButton.dailyPerformance.name,
          onBeforeExit: () async {
            return !_loading && await _dailyPerformanceCubit.saveBeforeExit();
          },
          showSaveConfirmation: false,
          child: _content(context),
        );
      }),
    );
  }

  /// 與學生名冊、每日出席相同：共用頁首（標題、主操作、篩選）＋資訊列，
  /// 與卡片列表一起捲動；卡片列仍以 SliverList 延遲建立。
  Widget _content(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return BlocBuilder<DailyPerformanceCubit, StudentDailyPerformanceState>(
        builder: (context, state) {
      final records = state.dailyPerformanceInfo.records;
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
            return LayoutBuilder(builder: (context, constraints) {
              // iPad 1024 寬扣除頁框後約 976，仍應呈現雙欄。
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final rows = (filteredRecords.length + columns - 1) ~/ columns;
              return CustomScrollView(slivers: [
                if (_loadError != null)
                  SliverToBoxAdapter(
                      child: TextButton(
                          onPressed: _loadPerformanceData,
                          child: Text('$_loadError（重試）'))),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: gap / 2),
                    child: SystemPageHeader(
                      title: '今日表現',
                      subtitle: '記錄評分、作業與品格表現，離開時自動儲存。',
                      action: ElevatedButton.icon(
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
                            minimumSize: const Size(44, 52),
                            padding: EdgeInsets.symmetric(
                                horizontal: gap * 1.25, vertical: gap)),
                        icon: const Icon(Icons.save),
                        label: const Text('儲存'),
                      ),
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
                        label: _loading
                            ? '正在載入表現紀錄…'
                            : '${_classLocationFilterNotifier.value.name}  ·  ${filteredRecords.length} 位學生')),
                if (_loading)
                  const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator())))
                else if (filteredRecords.isEmpty)
                  SliverToBoxAdapter(
                      child: _emptyState(context, searchText.isNotEmpty))
                else
                  SliverList.separated(
                    itemCount: rows,
                    separatorBuilder: (_, __) => SizedBox(height: gap),
                    itemBuilder: (context, row) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var column = 0; column < columns; column++) ...[
                            if (column > 0) SizedBox(width: gap),
                            Expanded(
                                child: row * columns + column <
                                        filteredRecords.length
                                    ? DailyPerformanceRecordCard(
                                        filteredRecords[row * columns + column])
                                    : const SizedBox()),
                          ],
                        ]),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: gap)),
              ]);
            });
          });
    });
  }

  Widget _emptyState(BuildContext context, bool searching) {
    final ds = SystemTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(ds.metric('spaceMedium')),
      child: Column(children: [
        Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
                color: ds.surfaceTone(100), shape: BoxShape.circle),
            child: Icon(Icons.person_search_rounded,
                size: 44, color: ds.brandTone(700))),
        const SizedBox(height: 16),
        Text(searching ? '找不到符合搜尋條件的學生' : '這個據點目前沒有表現紀錄，請切換其他據點。',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: ds.metric('bodySize'),
                color: ds.color('secondaryText'))),
        if (searching) ...[
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _searchTextNotifier.value = '';
              },
              child: const Text('清除搜尋')),
        ],
      ]),
    );
  }
}

/// 卡片內的評分／描述分區：用 SystemTheme 表面與邊框，Light／Dark 皆可讀。
BoxDecoration _panelDecoration(BuildContext context) {
  final ds = SystemTheme.of(context);
  return BoxDecoration(
    color: ds.color('secondaryBackground'),
    borderRadius: BorderRadius.circular(ds.metric('radiusSmall')),
    border: Border.fromBorderSide(ds.cardBorder),
  );
}

class DailyPerformanceRecordCard extends StatelessWidget {
  final StudentDailyPerformanceRecord student;

  const DailyPerformanceRecordCard(this.student, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: student.classPerformanceRatingNotifier,
      builder: (context, classPerformanceRating, _) {
        // 與每日點名卡一致：白色卡面、語意色框線（依上課表現評分）、姓名首字圓章。
        final ds = SystemTheme.of(context);
        final performanceColor =
            ds.color(_ratingToneKey(classPerformanceRating));
        final name = student.name.trim();

        return Material(
          color: ds.color('secondaryBackground'),
          shape: RoundedRectangleBorder(
              borderRadius: ds.cardRadius,
              side: BorderSide(
                  color: performanceColor.withOpacity(.45), width: 1.5)),
          child: Padding(
            padding: EdgeInsets.all(ds.metric('spaceMedium')),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 学生姓名和详情图标
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: ds.surfaceTone(100), shape: BoxShape.circle),
                      child: Text(name.isEmpty ? '?' : name.characters.first,
                          style: TextStyle(
                              fontSize: ds.metric('bodySize'),
                              fontWeight: FontWeight.w700,
                              color: ds.brandTone(700))),
                    ),
                    SizedBox(width: ds.metric('spaceSmall') * 1.5),
                    Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: ds.metric('bodySize') + 2,
                                fontWeight: FontWeight.w700,
                                color: ds.color('primaryText')))),
                    const SizedBox(width: 8),
                    Material(
                      color: ds.surfaceTone(100),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: '查看${student.name}的表現紀錄',
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
                        icon: Icon(Icons.insights_rounded,
                            color: ds.brandTone(700), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 顯示已選擇的優秀品格標籤
                ValueListenableBuilder(
                  valueListenable: student.excellentCharactersNotifier,
                  builder: (context, excellentCharacters, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: SystemTheme.of(context).brandTone(700),
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

                        // 選擇器本身已標示選取狀態，不再另列一排已選標籤。
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // 五度量表評分區域
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: _panelDecoration(context),
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
                  decoration: _panelDecoration(context),
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
                          // 底色、邊框與文字色交給 SystemTheme 的 inputDecorationTheme。
                          decoration: const InputDecoration(
                            hintText: '請輸入表現描述',
                            isDense: true,
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

  // 評分對應的語意色 key（與五分量表相同），由 SystemTheme 依主題與明暗解析。
  String _ratingToneKey(int rating) => switch (rating) {
        5 => 'success',
        4 => 'info',
        3 => 'warning',
        2 => 'accent3',
        1 => 'error',
        _ => 'border',
      };
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
