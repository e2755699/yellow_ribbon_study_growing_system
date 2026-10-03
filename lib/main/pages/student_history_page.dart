import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/presentation/components/system_page.dart';
import '../../design_system/presentation/system_theme_scope.dart';
import '../../domain/model/roster/roster_models.dart';
import '../../domain/bloc/student_history_cubit/student_history_cubit.dart';
import '../components/roster/student_history_view.dart';

class StudentHistoryPage extends StatefulWidget {
  const StudentHistoryPage({super.key});
  @override
  State<StudentHistoryPage> createState() => _StudentHistoryPageState();
}

class _StudentHistoryPageState extends State<StudentHistoryPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) => SystemThemeScope(
      builder: (context) => SystemPage(
          scaffoldKey: scaffoldKey,
          title: '學生歷史與成長',
          child: BlocBuilder<StudentHistoryCubit, StudentHistoryState>(
              builder: (context, state) {
            final cubit = context.read<StudentHistoryCubit>();
            return StudentHistoryView(
                monthLabel: state.month.value.substring(0, 7),
                history: state.history,
                loading: state.loading,
                error: state.error,
                onPrevious: () => cubit.moveMonth(-1),
                onNext: () => cubit.moveMonth(1),
                onRetry: cubit.start,
                onPickMonth: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: state.month.calendar,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (date != null) cubit.open(BusinessDate.fromCalendar(date));
                },
                onOpenDay: (record) => context.push(Uri(
                        path: record.kind == 'attendance'
                            ? '/dailyAttendance'
                            : '/dailyPerformance',
                        queryParameters: {
                          'date': record.date.value,
                          'site': record.locationId
                        }).toString()));
          })));
}
