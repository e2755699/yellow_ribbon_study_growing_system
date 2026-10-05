import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import '../../../design_system/presentation/system_theme_scope.dart';
import '../../../design_system/presentation/components/system_page.dart';
import 'student_detail_main_section.dart';

class StudentDetailPageWidget extends StatefulWidget {
  const StudentDetailPageWidget({super.key});
  factory StudentDetailPageWidget.fromRouteParams(
          Operate operate, String sid) =>
      const StudentDetailPageWidget();

  @override
  State<StudentDetailPageWidget> createState() =>
      StudentDetailPageWidgetState();
}

class StudentDetailPageWidgetState extends State<StudentDetailPageWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<StudentDetailMainSectionState>();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StudentDetailCubit, StudentDetailState>(
        builder: (context, state) {
          final cubit = context.read<StudentDetailCubit>();
          final authorized = cubit.roster == null || cubit.access != null;
          final showForm = authorized &&
              (state is StudentDetailLoaded ||
                  (state is StudentDetailError &&
                      (!state.isView || state.detail.id != null)));
          return SystemThemeScope(
              builder: (context) => SystemPage(
                    scaffoldKey: _scaffoldKey,
                    title: '學生資料',
                    hasUnsavedChanges: () =>
                        !(_formKey.currentState?.isBusy ?? false) &&
                        (_formKey.currentState?.hasUnsavedChanges ??
                            cubit.hasUnsavedChanges()),
                    onBeforeExit: () async {
                      if (_formKey.currentState?.isBusy ?? false) return false;
                      if (!(_formKey.currentState?.hasUnsavedChanges ??
                          cubit.hasUnsavedChanges())) return true;
                      return await _formKey.currentState?.saveForm() ?? false;
                    },
                    child: showForm
                        ? Column(children: [
                            if (state is StudentDetailError)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Semantics(
                                    liveRegion: true,
                                    child: Text(state.message,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error))),
                              ),
                            Expanded(
                                child: StudentDetailMainSection(
                                    key: _formKey,
                                    studentDetail: state.detail)),
                          ])
                        : !authorized
                            ? const Center(child: Text('正在確認帳號權限，請稍候或聯絡管理者'))
                            : state is StudentDetailError
                                ? Center(child: Text(state.message))
                                : const Center(
                                    child: CircularProgressIndicator()),
                  ));
        },
      );
}
