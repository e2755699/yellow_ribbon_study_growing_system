import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/model/bloc/student_cubit/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/model/enum/operate.dart';

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(super.initialState);
}

class StudentDetailState {
  final StudentDetail detail;
  final Operate operate;

  StudentDetailState(this.detail, this.operate);
}
