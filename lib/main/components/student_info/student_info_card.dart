import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/bloc/student_cubit/student_cubit.dart';
import '../../../domain/enum/operate.dart';
import '../../../domain/model/student/student_detail.dart';
import '../../../flutter_flow/nav/nav.dart';
import 'student_identity_card.dart';

class StudentInfoCard extends StatefulWidget {
  const StudentInfoCard(
      {super.key,
      required this.student,
      this.compact = false,
      this.ribbonCount,
      this.canManage = false});
  final int? ribbonCount;
  final StudentDetail student;
  final bool compact;
  final bool canManage;
  @override
  State<StudentInfoCard> createState() => _StudentInfoCardState();
}

class _StudentInfoCardState extends State<StudentInfoCard> {
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
              title: const Text('離班／封存学生'),
              content: Text(
                  '將「${widget.student.name}」設為今天起離班？歷史出席、表現與緞帶會保留。指定其他日期請到學生詳情的就讀異動。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('取消')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('確認離班')),
              ],
            ));
    if (confirmed != true || !mounted || widget.student.id == null) return;
    try {
      await cubit.deleteStudent(widget.student.id!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('離班異動未完成，請確認權限或就讀日期後重試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => StudentIdentityCard(
      student: widget.student,
      compact: widget.compact,
      ribbonCount: widget.ribbonCount,
      onOpen: () => _open(Operate.view),
      onEdit: () => _open(Operate.edit),
      onDelete: widget.canManage && !widget.student.archived ? _delete : null);
}
