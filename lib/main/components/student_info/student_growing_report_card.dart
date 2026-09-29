import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';

/// 成長報告名冊列：與學生名冊共用卡片表面、頭像環與強調色，
/// 整張卡片可點進個人歷史表現。
class StudentGrowingReportCard extends StatelessWidget with YbToolbox {
  final StudentDetail student;

  /// 點擊行為；未提供時導向個人歷史表現（App 預設），展示時可注入。
  final VoidCallback? onOpen;

  const StudentGrowingReportCard(
      {super.key, required this.student, this.onOpen});

  void _open(BuildContext context) => context.pushNamed(
        YbRoute.studentHistoryPerformance.name,
        pathParameters: {'studentId': student.id!},
      );

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    final school = student.school.trim().isEmpty ? '尚未填寫學校' : student.school;
    return Material(
      color: ds.color('secondaryBackground'),
      shape: RoundedRectangleBorder(
          borderRadius: ds.cardRadius, side: ds.cardBorder),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen ?? () => _open(context),
        hoverColor: ds.primary.withOpacity(ds.metric('hoverDarken')),
        highlightColor: ds.primary.withOpacity(ds.metric('pressedDarken')),
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: ds.surfaceTone(100), shape: BoxShape.circle),
                child: StudentAvatar(
                  avatarFileName: student.avatar,
                  gender: student.gender,
                  size: 44,
                  onAvatarSelected: null,
                  yellowRibbonCount: null,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: ds.metric('bodySize') + 2,
                          fontWeight: FontWeight.w700,
                          color: ds.color('primaryText'))),
                  const SizedBox(height: 4),
                  Text('${student.gender} · $school',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: ds.metric('labelSize'),
                          color: ds.color('secondaryText'))),
                ],
              )),
              SizedBox(width: gap / 2),
              // 個人表現入口：品牌淺底膠囊，與卡片點擊同一目的地。
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: EdgeInsets.symmetric(horizontal: gap * .75),
                decoration: ShapeDecoration(
                    color: ds.surfaceTone(50),
                    shape: StadiumBorder(
                        side: BorderSide(color: ds.surfaceTone(200)))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.insights_rounded,
                      size: 18, color: ds.brandTone(700)),
                  const SizedBox(width: 6),
                  Text('個人表現',
                      style: TextStyle(
                          fontSize: ds.metric('labelSize'),
                          fontWeight: FontWeight.w700,
                          color: ds.brandTone(700))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
