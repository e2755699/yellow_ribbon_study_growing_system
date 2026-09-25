import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';

enum HomeButton {
  studentInfo("學生資料", "students"),
  dailyAttendance("每日出席", "everyday"),
  dailyPerformance("每日表現", "star"),
  growingReport("成長報告", "school");

  final String name;
  final String iconName;

  const HomeButton(this.name, this.iconName);

  get routeName => {
        HomeButton.studentInfo: YbRoute.studentInfo.routeName,
        HomeButton.dailyAttendance: YbRoute.dailyAttendance.routeName,
        HomeButton.dailyPerformance: YbRoute.dailyPerformance.routeName,
        HomeButton.growingReport: YbRoute.growingReport.routeName,
      }[this];
}
