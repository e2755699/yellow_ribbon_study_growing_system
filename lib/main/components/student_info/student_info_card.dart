import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';

class StudentInfoCard extends StatelessWidget with YbToolbox {
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
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              context.push(
                  "${YbRoute.studentDetail.routeName}/${Operate.view.name}/${student.id!}");
            },
          ),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.name),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.gender),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          Text(student.school),
          const Spacer(),
          editButton(context, onPressed: () {
            context.push(
                "${YbRoute.studentDetail.routeName}/${Operate.edit.name}/${student.id!}");
          }),
          Gap(FlutterFlowTheme.of(context).spaceMedium),
          deleteButton(context, onPressed: () {
            context.read<StudentsCubit>().deleteStudent(student.id!);
            context.pop();
          }),
        ],
      ),
    );
  }
}
