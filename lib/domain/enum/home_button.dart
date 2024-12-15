import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';

enum HomeButton {
  studentInfo("課輔資料", "students"),
  dailyAttendance("每日出勤", "everyday"),
  studentAssessment("成長評量", "assessment"),
  growingReport("成長報告", "school");

  final String name;
  final String iconName;

  const HomeButton(this.name, this.iconName);

  get routeName => {
        HomeButton.studentInfo: YbRoute.studentInfo.routeName,
        HomeButton.dailyAttendance: YbRoute.dailyAttendance.routeName,
      }[this];
}
