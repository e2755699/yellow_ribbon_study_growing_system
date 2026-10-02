import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/roster/roster_policy.dart';

class AttendanceStatisticsCard extends StatelessWidget {
  final AttendanceStatistics statistics;
  final bool unknownEnrollmentCoverage, fromCache;
  const AttendanceStatisticsCard(
      {super.key,
      required this.statistics,
      this.unknownEnrollmentCoverage = false,
      this.fromCache = false});
  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context), stats = statistics;
    final complete = stats.isFinal && !unknownEnrollmentCoverage && !fromCache;
    final rate = stats.rate == null
        ? '資料不足'
        : '${complete ? '出席率' : '暫算出席率'} ${(stats.rate! * 100).toStringAsFixed(1)}%';
    return SystemSectionCard(
        title: '本月出席統計',
        icon: Icons.fact_check_outlined,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(rate,
              style: TextStyle(
                  fontSize: ds.metric('titleSize'),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: ds.metric('spaceSmall')),
          Text(
              '應到 ${stats.expected} 次 · 已確認 ${stats.confirmed}/${stats.expected} 次 · 到席 ${stats.present} 次'),
          Text('到席含準時、遲到與早退；入班前及取消上課不列分母。',
              style: TextStyle(
                  color: ds.color('secondaryText'),
                  fontSize: ds.metric('labelSize'))),
          if (!complete) ...[
            SizedBox(height: ds.metric('spaceSmall')),
            Text(unknownEnrollmentCoverage
                ? '部分就讀期間尚未核對，目前只能呈現已知期間的暫算值。'
                : stats.uncertainSessions > 0
                    ? '另有 ${stats.uncertainSessions} 個歷史上課日待確認。'
                    : stats.expected == 0
                        ? '此期間沒有已確認的應出席課次。'
                        : stats.confirmed < stats.expected
                            ? '仍有未完成點名，請勿視為最終出席率。'
                            : '點名完整，等待雲端確認最新資料。'),
          ],
          if (fromCache) const Text('目前為快取資料，等待雲端確認。'),
        ]));
  }
}
