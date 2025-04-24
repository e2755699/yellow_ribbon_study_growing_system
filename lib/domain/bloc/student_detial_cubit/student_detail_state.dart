import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

enum Operate {
  view,
  edit,
  create;

  bool get isView => this == view;
  bool get isEdit => this == edit;
  bool get isCreate => this == create;
}

abstract class StudentDetailState {}

class StudentDetailInitial extends StudentDetailState {}

class StudentDetailLoading extends StudentDetailState {}

class StudentDetailLoaded extends StudentDetailState {
  final StudentDetail studentDetail;
  final Operate operate;

  StudentDetailLoaded({
    required this.studentDetail,
    required this.operate,
  });
}

class StudentDetailError extends StudentDetailState {
  final String message;

  StudentDetailError(this.message);
}
