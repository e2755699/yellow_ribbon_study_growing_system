import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/bloc/student_cubit/student_cubit.dart';
import '../../../domain/enum/operate.dart';
import '../../../domain/model/student/student_detail.dart';
import '../../../domain/repo/yellow_ribbon_repo.dart';
import '../../../flutter_flow/nav/nav.dart';
import 'student_identity_card.dart';

class StudentInfoCard extends StatefulWidget {
  const StudentInfoCard(
      {super.key, required this.student, this.compact = false});
  final StudentDetail student;
  final bool compact;
  @override
  State<StudentInfoCard> createState() => _StudentInfoCardState();
}

class _StudentInfoCardState extends State<StudentInfoCard> {
  int? _yellowRibbonCount;

  @override
  void initState() {
    super.initState();
    _loadYellowRibbonCount();
  }

  Future<void> _loadYellowRibbonCount() async {
    if (widget.student.id == null) return;
    try {
      final count =
          await YellowRibbonRepo().getStudentRibbonCount(widget.student.id!);
      if (mounted) setState(() => _yellowRibbonCount = count.unusedCount);
    } catch (_) {
      // Keep the directory usable when the count cannot be loaded.
    }
  }

  Future<void> _open(Operate mode) async {
    if (widget.student.id == null) return;
    await context.push(
        '${YbRoute.studentDetail.routeName}/${mode.name}/${widget.student.id}');
    if (mounted) context.read<StudentsCubit>().load();
  }

  Future<void> _delete() async {
    final cubit = context.read<StudentsCubit>();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('刪除學生'),
              content: Text('確定要刪除「${widget.student.name}」的資料嗎？此操作無法復原。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('取消')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('刪除')),
              ],
            ));
    if (confirmed != true || !mounted || widget.student.id == null) return;
    try {
      await cubit.deleteStudent(widget.student.id!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('刪除失敗，請重試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => StudentIdentityCard(
      student: widget.student,
      compact: widget.compact,
      ribbonCount: _yellowRibbonCount,
      onOpen: () => _open(Operate.view),
      onEdit: () => _open(Operate.edit),
      onDelete: _delete);
}
