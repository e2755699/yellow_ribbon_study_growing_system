import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';

enum HomeButton {
  studentInfo("學生資料", "students"),
  dailyAttendance("每日出席", "everyday"),
  dailyPerformance("每日表現", "star"),
  // studentPerformance("學生表現", "performance"),
  // studentAssessment("成長評量", "assessment"),
  growingReport("成長報告", "school");

  final String name;
  final String iconName;

  const HomeButton(this.name, this.iconName);

  get routeName => {
        HomeButton.studentInfo: YbRoute.studentInfo.routeName,
        HomeButton.dailyAttendance: YbRoute.dailyAttendance.routeName,
        HomeButton.dailyPerformance: YbRoute.dailyPerformance.routeName,
        // HomeButton.studentPerformance: YbRoute.studentPerformance.routeName,
        // HomeButton.studentAssessment: YbRoute.studentInfo.routeName, // 暂时重定向到学生信息页面
        HomeButton.growingReport: YbRoute.growingReport.routeName,
      }[this];
}
