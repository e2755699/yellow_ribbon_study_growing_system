import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart'
    as detail_state;
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yellow_ribbon/yellow_ribbon_count.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/yellow_ribbon_repo.dart';

class StudentInfoCard extends StatefulWidget {
  final StudentDetail student;

  const StudentInfoCard({super.key, required this.student});

  @override
  State<StudentInfoCard> createState() => _StudentInfoCardState();
}

class _StudentInfoCardState extends State<StudentInfoCard> {
  int _yellowRibbonCount = 0;

  @override
  void initState() {
    super.initState();
    _loadYellowRibbonCount();
  }

  Future<void> _loadYellowRibbonCount() async {
    if (widget.student.id != null) {
      final yellowRibbonRepo = YellowRibbonRepo();
      final ribbonCount =
          await yellowRibbonRepo.getStudentRibbonCount(widget.student.id!);

      if (mounted) {
        setState(() {
          _yellowRibbonCount = ribbonCount.unusedCount;
        });
      }
    }
  }

  Widget _editButton(BuildContext context, {required VoidCallback onPressed}) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: onPressed,
      tooltip: '編輯',
    );
  }

  Widget _deleteButton(BuildContext context,
      {required VoidCallback onPressed}) {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: onPressed,
      tooltip: '刪除',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentDetailCubit, detail_state.StudentDetailState>(
      builder: (context, state) {
        if (state is detail_state.StudentDetailLoaded) {
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
                  avatarFileName: state.studentDetail.avatar,
                  size: 40,
                  onAvatarSelected: null,
                  yellowRibbonCount: null,
                ),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                YellowRibbonCount(
                  count: _yellowRibbonCount,
                  size: 16,
                ),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                Text(state.studentDetail.name),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                Text(state.studentDetail.gender),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                Text(state.studentDetail.school),
                const Spacer(),
                _editButton(context, onPressed: () {
                  context.push(
                      "${YbRoute.studentDetail.routeName}/${Operate.edit.name}/${state.studentDetail.id!}");
                }),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                _deleteButton(context, onPressed: () {
                  context
                      .read<StudentsCubit>()
                      .deleteStudent(state.studentDetail.id!);
                  context.pop();
                }),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
