import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../backend/firebase_analytics/analytics.dart';
import '../../../design_system/presentation/system_theme_scope.dart';
import '../../../design_system/presentation/components/system_page.dart';
import '../../../domain/bloc/student_cubit/student_cubit.dart';
import '../../../domain/enum/operate.dart';
import '../../../flutter_flow/nav/nav.dart';
import '../../components/student_info/student_info_card.dart';
import 'student_directory_view.dart';

class StudentInfoPageWidget extends StatefulWidget {
  const StudentInfoPageWidget({super.key});
  @override
  State<StudentInfoPageWidget> createState() => StudentInfoPageWidgetState();
}

class StudentInfoPageWidgetState extends State<StudentInfoPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'studentInfoPage'});
  }

  Future<void> _createStudent() async {
    await context
        .push('${YbRoute.studentDetail.routeName}/${Operate.create.name}/null');
    if (mounted) context.read<StudentsCubit>().load();
  }

  @override
  Widget build(BuildContext context) => SystemThemeScope(
      builder: (context) => SystemPage(
          scaffoldKey: scaffoldKey,
          title: '學生資料',
          child: BlocBuilder<StudentsCubit, StudentsState>(
              builder: (context, state) => StudentDirectoryView(
                  state: state,
                  onCreate: _createStudent,
                  onRetry: () => context.read<StudentsCubit>().load(),
                  itemBuilder: (student, compact) => StudentInfoCard(
                      key: ValueKey(student.id),
                      student: student,
                      compact: compact)))));
}
