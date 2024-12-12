enum HomeButton {
  studentInfo("課輔資料", "students", "/student"),
  dailyAttendance("每日出勤", "everyday", "/dailyAttendance"),
  studentAssessment("成長評量", "assessment", "/assessment"),
  growingReport("成長報告", "school", "/school");

  final String name;
  final String iconName;
  final String routeName;

  const HomeButton(this.name, this.iconName, this.routeName);
}
