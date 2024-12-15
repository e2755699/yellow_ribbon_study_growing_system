import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(super.initialState);
}

class StudentDetailState {
  final StudentDetail detail;
  final Operate operate;

  StudentDetailState(this.detail, this.operate);
}
