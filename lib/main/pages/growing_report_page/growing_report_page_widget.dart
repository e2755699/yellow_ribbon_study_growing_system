import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/search_field/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class GrowingReportPageWidget extends StatefulWidget {
  const GrowingReportPageWidget({super.key});

  @override
  State<GrowingReportPageWidget> createState() => GrowingReportPageWidgetState();
}

class GrowingReportPageWidgetState extends State<GrowingReportPageWidget>
    with YbToolbox {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<ClassLocation> _classLocationFilterNotifier =
      ValueNotifier(ClassLocation.values.first);
  
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'growingReportPage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();
    
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YbLayout(
        scaffoldKey: scaffoldKey,
        title: HomeButton.growingReport.name,
        child: Column(
          children: [
            tabSection(_classLocationFilterNotifier, operators: () {
              return [
                YbSearchField(
                  controller: _searchController,
                  hintText: '搜尋學生姓名...',
                  onChanged: (value) {
                    _searchTextNotifier.value = value;
                  },
                ),
              ];
            }),
            Gap(FlutterFlowTheme.of(context).spaceLarge),
            Expanded(
              child: BlocProvider(
                create: (context) => StudentsCubit(StudentsState([]))..load(),
                child: BlocBuilder<StudentsCubit, StudentsState>(
                    builder: (context, state) {
                  return ValueListenableBuilder(
                      valueListenable: _classLocationFilterNotifier,
                      builder: (context, filter, _) {
                        return ValueListenableBuilder<String>(
                          valueListenable: _searchTextNotifier,
                          builder: (context, searchText, _) {
                            var students = state.students
                                .where((student) =>
                                    student.classLocation == filter.name)
                                .toList();
                                
                            if (searchText.isNotEmpty) {
                              students = students
                                  .where((student) => student.name
                                      .toLowerCase()
                                      .contains(searchText.toLowerCase()))
                                  .toList();
                            }
                            
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisSpacing:
                                    FlutterFlowTheme.of(context).spaceMedium,
                                mainAxisSpacing:
                                    FlutterFlowTheme.of(context).spaceMedium,
                                crossAxisCount: 2,
                                childAspectRatio: 8 / 1,
                              ),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                var student = students[index];
                                return StudentGrowingReportCard(student: student);
                              },
                            );
                          }
                        );
                      });
                }),
              ),
            ),
          ],
        ));
  }
} 