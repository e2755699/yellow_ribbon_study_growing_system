import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/presentation/system_theme_scope.dart';
import '../../../design_system/presentation/components/system_page.dart';
import '../../../domain/bloc/student_cubit/student_cubit.dart';
import '../../components/student_info/student_growing_report_card.dart';
import '../student_info_page/student_directory_view.dart';

class GrowingReportPageWidget extends StatefulWidget {
  const GrowingReportPageWidget({super.key});
  @override
  State<GrowingReportPageWidget> createState() =>
      GrowingReportPageWidgetState();
}

class GrowingReportPageWidgetState extends State<GrowingReportPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) => SystemThemeScope(
      builder: (context) => SystemPage(
          scaffoldKey: scaffoldKey,
          title: '成長報告',
          child: BlocBuilder<StudentsCubit, StudentsState>(
              builder: (context, state) {
            final cubit = context.read<StudentsCubit>();
            return StudentDirectoryView(
                title: '成長報告',
                subtitle: '選擇學生，查看有效就讀期間的出席率與已確認評量。',
                state: state,
                onCreate: null,
                onRetry: cubit.load,
                onSearch: cubit.search,
                onLocation: cubit.selectLocation,
                onIncludeArchived: cubit.includeArchived,
                itemBuilder: (student, compact) =>
                    StudentGrowingReportCard(student: student));
          })));
}
