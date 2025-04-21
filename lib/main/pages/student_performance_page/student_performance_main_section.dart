import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_performance_cubit/student_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/rating_scale/five_point_rating_scale.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/info_card_layout.dart';

class StudentPerformanceMainSection extends StatefulWidget {
  final String studentId;
  final List<StudentDailyPerformanceRecord> records;
  final bool isEditing;
  final Function(StudentDailyPerformanceRecord)? onRecordChanged;
  final StudentDetail? studentDetail;
  final Map<String, String>? customTitles;

  const StudentPerformanceMainSection({
    super.key,
    required this.studentId,
    required this.records,
    this.isEditing = false,
    this.onRecordChanged,
    this.studentDetail,
    this.customTitles,
  });

  @override
  State<StudentPerformanceMainSection> createState() =>
      _StudentPerformanceMainSectionState();
}

class _StudentPerformanceMainSectionState
    extends State<StudentPerformanceMainSection> with YbToolbox {
  // 获取近一个月的记录
  List<StudentDailyPerformanceRecord> get recentRecords {
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

    return widget.records
        .where((record) =>
            record.recordDate.isAfter(oneMonthAgo) ||
            record.recordDate.isAtSameMomentAs(oneMonthAgo))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = recentRecords;

    // 获取自定义标题或使用默认标题
    final recordsTitle = widget.customTitles?['recordsTitle'] ?? '表現記錄（近一個月）';
    final statsTitle = widget.customTitles?['statsTitle'] ?? '表現統計（近一個月）';
    final emptyMessage =
        widget.customTitles?['emptyMessage'] ?? '找不到該學生近一個月的表現記錄';

    // 使用自定义标题时，不过滤记录
    final recordsToShow =
        widget.customTitles != null ? widget.records : filteredRecords;

    if (recordsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
            const Gap(16),
            Text(
              emptyMessage,
              style: FlutterFlowTheme.of(context).titleMedium,
            ),
          ],
        ),
      );
    }

    // 获取学生姓名（从第一条记录中获取）
    final studentName = widget.studentDetail?.name ??
        (filteredRecords.isNotEmpty ? filteredRecords[0].name : '');
    final classLocation = widget.studentDetail?.classLocation ??
        (filteredRecords.isNotEmpty
            ? filteredRecords[0].classLocation.name
            : '');
    final school = widget.studentDetail?.school ?? '';
    // 年级信息可能需要从学校名称中提取或者从其他地方获取

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学生基本信息卡片
            InfoCardLayoutWith1Column(
              title: '學生基本資料',
              columns1: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '姓名：$studentName',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                      const Gap(8),
                      Text(
                        '據點：$classLocation',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                      const Gap(8),
                      Text(
                        '學校：$school',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            // 表现记录卡片
            InfoCardLayoutWith1Column(
              title: recordsTitle,
              titleSuffix: widget.studentId.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: '查看所有歷史表現',
                      onPressed: () {
                        // 跳转到历史表现页面，传递学生ID
                        context.pushNamed(
                          'studentHistoryPerformance',
                          pathParameters: {'studentId': widget.studentId},
                        );
                      },
                    )
                  : null,
              columns1: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 300, // 设置固定高度为300
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            _sortRecordsByDate(recordsToShow).map((record) {
                          return _buildPerformanceCard(context, record);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Gap(16),

            // 表现统计卡片
            InfoCardLayoutWith1Column(
              title: statsTitle,
              columns1: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPerformanceStats(context, recordsToShow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      BuildContext context, StudentDailyPerformanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期
            Text(
              '日期：${_formatDate(record)}',
              style: FlutterFlowTheme.of(context).titleSmall,
            ),
            const Divider(),

            // 主要表現評分部分
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上課表現評分（原有的）
                Row(
                  children: [
                    const Text('上課表現評級：'),
                    const Gap(8),
                    Expanded(
                      child: widget.isEditing
                          ? _buildPerformanceRatingDropdown(record)
                          : ValueListenableBuilder(
                              valueListenable: record.performanceRatingNotifier,
                              builder: (context, performanceRating, _) => Text(
                                performanceRating.label,
                                style: TextStyle(
                                  color:
                                      _getPerformanceColor(performanceRating),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const Gap(16),

                // 五度量表評分區域
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '課程表現評分：',
                    style: FlutterFlowTheme.of(context).labelLarge,
                  ),
                ),

                // 五度量表評分 - 上課表現
                FivePointRatingScale(
                  value: record.classPerformanceRatingNotifier.value,
                  isEditable: widget.isEditing,
                  onChanged: (value) {
                    if (widget.isEditing) {
                      record.classPerformanceRatingNotifier.value = value;
                      if (widget.onRecordChanged != null) {
                        widget.onRecordChanged!(record);
                      }
                    }
                  },
                  title: '上課表現',
                ),
                const Gap(8),

                // 五度量表評分 - 數學成績
                FivePointRatingScale(
                  value: record.mathPerformanceRatingNotifier.value,
                  isEditable: widget.isEditing,
                  onChanged: (value) {
                    if (widget.isEditing) {
                      record.mathPerformanceRatingNotifier.value = value;
                      if (widget.onRecordChanged != null) {
                        widget.onRecordChanged!(record);
                      }
                    }
                  },
                  title: '數學成績',
                ),
                const Gap(8),

                // 五度量表評分 - 國文成績
                FivePointRatingScale(
                  value: record.chinesePerformanceRatingNotifier.value,
                  isEditable: widget.isEditing,
                  onChanged: (value) {
                    if (widget.isEditing) {
                      record.chinesePerformanceRatingNotifier.value = value;
                      if (widget.onRecordChanged != null) {
                        widget.onRecordChanged!(record);
                      }
                    }
                  },
                  title: '國文成績',
                ),
                const Gap(8),

                // 五度量表評分 - 英文成績
                FivePointRatingScale(
                  value: record.englishPerformanceRatingNotifier.value,
                  isEditable: widget.isEditing,
                  onChanged: (value) {
                    if (widget.isEditing) {
                      record.englishPerformanceRatingNotifier.value = value;
                      if (widget.onRecordChanged != null) {
                        widget.onRecordChanged!(record);
                      }
                    }
                  },
                  title: '英文成績',
                ),
                const Gap(8),

                // 五度量表評分 - 社會成績
                FivePointRatingScale(
                  value: record.socialPerformanceRatingNotifier.value,
                  isEditable: widget.isEditing,
                  onChanged: (value) {
                    if (widget.isEditing) {
                      record.socialPerformanceRatingNotifier.value = value;
                      if (widget.onRecordChanged != null) {
                        widget.onRecordChanged!(record);
                      }
                    }
                  },
                  title: '社會成績',
                ),
                const Gap(16),

                // 其他信息
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：完成作业
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 是否完成作业
                          Row(
                            children: [
                              const Text('完成作業：'),
                              const Gap(8),
                              widget.isEditing
                                  ? _buildHomeworkCompletedCheckbox(record)
                                  : ValueListenableBuilder(
                                      valueListenable:
                                          record.homeworkCompletedNotifier,
                                      builder:
                                          (context, homeworkCompleted, _) =>
                                              Text(
                                        homeworkCompleted ? '是' : '否',
                                        style: TextStyle(
                                          color: homeworkCompleted
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 右侧：小帮手
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 是否小帮手
                          Row(
                            children: [
                              const Text('小幫手：'),
                              const Gap(8),
                              widget.isEditing
                                  ? _buildHelperCheckbox(record)
                                  : ValueListenableBuilder(
                                      valueListenable: record.isHelperNotifier,
                                      builder: (context, isHelper, _) => Text(
                                        isHelper ? '是' : '否',
                                        style: TextStyle(
                                          color: isHelper
                                              ? Colors.blue
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 表現描述（放在最下面）
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('表現描述：'),
                      const Gap(8),
                      Expanded(
                        child: widget.isEditing
                            ? _buildRemarksTextField(record)
                            : ValueListenableBuilder(
                                valueListenable: record.remarksNotifier,
                                builder: (context, remarks, _) => Text(
                                  remarks.isEmpty ? '無' : remarks,
                                  style: TextStyle(
                                    fontStyle: remarks.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: remarks.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRatingDropdown(StudentDailyPerformanceRecord record) {
    return DropdownButton<PerformanceRating>(
      value: record.performanceRatingNotifier.value,
      isExpanded: true,
      onChanged: (PerformanceRating? newValue) {
        if (newValue != null) {
          record.performanceRatingNotifier.value = newValue;
          if (widget.onRecordChanged != null) {
            widget.onRecordChanged!(record);
          }
        }
      },
      items: PerformanceRating.values
          .map<DropdownMenuItem<PerformanceRating>>((PerformanceRating value) {
        return DropdownMenuItem<PerformanceRating>(
          value: value,
          child: Text(
            value.label,
            style: TextStyle(
              color: _getPerformanceColor(value),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHomeworkCompletedCheckbox(StudentDailyPerformanceRecord record) {
    return Checkbox(
      value: record.homeworkCompletedNotifier.value,
      onChanged: (bool? value) {
        if (value != null) {
          record.homeworkCompletedNotifier.value = value;
          if (widget.onRecordChanged != null) {
            widget.onRecordChanged!(record);
          }
        }
      },
    );
  }

  Widget _buildHelperCheckbox(StudentDailyPerformanceRecord record) {
    return Checkbox(
      value: record.isHelperNotifier.value,
      onChanged: (bool? value) {
        if (value != null) {
          record.isHelperNotifier.value = value;
          if (widget.onRecordChanged != null) {
            widget.onRecordChanged!(record);
          }
        }
      },
    );
  }

  Widget _buildRemarksTextField(StudentDailyPerformanceRecord record) {
    final controller =
        TextEditingController(text: record.remarksNotifier.value);

    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: '輸入表現描述',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      onChanged: (value) {
        record.remarksNotifier.value = value;
        if (widget.onRecordChanged != null) {
          widget.onRecordChanged!(record);
        }
      },
    );
  }

  Widget _buildPerformanceStats(
      BuildContext context, List<StudentDailyPerformanceRecord> records) {
    // 计算各项统计数据
    int totalRecords = records.length;
    int homeworkCompletedCount = records
        .where((record) => record.homeworkCompletedNotifier.value)
        .length;
    int helperCount =
        records.where((record) => record.isHelperNotifier.value).length;

    // 计算各评级的数量
    Map<PerformanceRating, int> ratingCounts = {};
    for (var rating in PerformanceRating.values) {
      ratingCounts[rating] = 0;
    }

    for (var record in records) {
      var rating = record.performanceRatingNotifier.value;
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    // 計算各學科平均分數
    double classPerformanceAvg = _calculateAverageRating(
        records, (r) => r.classPerformanceRatingNotifier.value);
    double mathPerformanceAvg = _calculateAverageRating(
        records, (r) => r.mathPerformanceRatingNotifier.value);
    double chinesePerformanceAvg = _calculateAverageRating(
        records, (r) => r.chinesePerformanceRatingNotifier.value);
    double englishPerformanceAvg = _calculateAverageRating(
        records, (r) => r.englishPerformanceRatingNotifier.value);
    double socialPerformanceAvg = _calculateAverageRating(
        records, (r) => r.socialPerformanceRatingNotifier.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '總記錄數：$totalRecords',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(8),
        Text(
          '作業完成率：${totalRecords > 0 ? (homeworkCompletedCount / totalRecords * 100).toStringAsFixed(1) : 0}%',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(8),
        Text(
          '小幫手次數：$helperCount',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(16),

        // 學科平均分數統計
        Text(
          '學科平均分數統計：',
          style: FlutterFlowTheme.of(context).titleSmall,
        ),
        const Gap(8),
        Text(
          '上課表現平均分：${classPerformanceAvg.toStringAsFixed(1)}',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(4),
        Text(
          '數學成績平均分：${mathPerformanceAvg.toStringAsFixed(1)}',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(4),
        Text(
          '國文成績平均分：${chinesePerformanceAvg.toStringAsFixed(1)}',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(4),
        Text(
          '英文成績平均分：${englishPerformanceAvg.toStringAsFixed(1)}',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(4),
        Text(
          '社會成績平均分：${socialPerformanceAvg.toStringAsFixed(1)}',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
        const Gap(16),

        // 表现评级统计
        Text(
          '表現評級統計：',
          style: FlutterFlowTheme.of(context).titleSmall,
        ),
        const Gap(8),
        ...PerformanceRating.values.map((rating) {
          int count = ratingCounts[rating] ?? 0;
          double percentage = totalRecords > 0 ? count / totalRecords * 100 : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(rating),
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(8),
                Text(
                  '${rating.label}：$count 次 (${percentage.toStringAsFixed(1)}%)',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 計算平均評分
  double _calculateAverageRating(List<StudentDailyPerformanceRecord> records,
      int Function(StudentDailyPerformanceRecord) getRating) {
    if (records.isEmpty) return 0;

    int total = 0;
    for (var record in records) {
      total += getRating(record);
    }

    return total / records.length;
  }

  String _formatDate(StudentDailyPerformanceRecord record) {
    // 使用DateFormatter类格式化日期
    return DateFormatter.formatToYYYYMMDD(record.recordDate);
  }

  Color _getPerformanceColor(PerformanceRating rating) {
    switch (rating) {
      case PerformanceRating.excellent:
        return Colors.green;
      case PerformanceRating.good:
        return Colors.blue;
      case PerformanceRating.average:
        return Colors.orange;
      case PerformanceRating.poor:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<StudentDailyPerformanceRecord> _sortRecordsByDate(
      List<StudentDailyPerformanceRecord> records) {
    return List.from(records)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
  }
}
