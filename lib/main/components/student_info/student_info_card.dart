import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';

class StudentInfoCard extends StatelessWidget {
  final StudentDetail student;

  const StudentInfoCard({super.key, required this.student});

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
          const Icon(Icons.account_circle),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.name),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.school),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.gender),
          const Spacer(),
          TextButton.icon(
              icon: Icon(
                Icons.delete_forever_sharp,
                color: FlutterFlowTheme.of(context).error,
              ),
              onPressed: () {},
              label: Text(
                "刪除",
                style: TextStyle(color: FlutterFlowTheme.of(context).error),
              )),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          TextButton.icon(
              icon:
                  Icon(Icons.edit, color: FlutterFlowTheme.of(context).primary),
              onPressed: () {
                context.push(
                    "${YbRoute.studentDetail.routeName}/${Operate.edit.name}/${student.id}");
              },
              label: Text(
                "編輯",
                style: TextStyle(color: FlutterFlowTheme.of(context).primary),
              ))
        ],
      ),
    );
  }

}
