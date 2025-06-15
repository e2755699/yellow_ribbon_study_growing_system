import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

abstract class StudentDetailState {
  final Operate operate;
  final StudentDetail detail;

  const StudentDetailState({this.operate = Operate.view, required this.detail});

  bool get isView => operate.isView;

  bool get isEdit => operate.isEdit;

  bool get isCreate => operate.isCreate;
}

class StudentDetailInitial extends StudentDetailState {
  const StudentDetailInitial({super.operate, required super.detail});
}

class StudentDetailLoaded extends StudentDetailState {
  const StudentDetailLoaded({
    required super.detail,
    super.operate = Operate.view,
  });

  StudentDetailLoaded copyWith({
    StudentDetail? detail,
    Operate? operate,
  }) {
    return StudentDetailLoaded(
      detail: detail ?? this.detail,
      operate: operate ?? this.operate,
    );
  }
}

class StudentDetailError extends StudentDetailState {
  final String message;

  const StudentDetailError(this.message,
      {super.operate, required super.detail});
}
