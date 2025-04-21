import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';

class StudentGrowingReportCard extends StatelessWidget with YbToolbox {
  final StudentDetail student;

  const StudentGrowingReportCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(FlutterFlowTheme.of(context).spaceMedium),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.all(
            Radius.circular(FlutterFlowTheme.of(context).radiusSmall)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          StudentAvatar(
            avatarFileName: student.avatar,
            size: 40,
            onAvatarSelected: null,
            yellowRibbonCount: null,
          ),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.name),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.gender),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.school),
          const Spacer(),
          // 個人表現按鈕
          TextButton.icon(
            icon: const Icon(Icons.star, color: Colors.amber),
            label: const Text('個人表現'),
            onPressed: () {
              // 跳轉到學生歷史表現記錄頁面
              context.pushNamed(
                YbRoute.studentHistoryPerformance.name,
                pathParameters: {'studentId': student.id!},
              );
            },
          ),
        ],
      ),
    );
  }
}
