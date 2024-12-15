import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';

class ClassLocationDropdownMenu extends StatelessWidget {
  final ValueNotifier<ClassLocation> _classLocationFilterNotifier;

  const ClassLocationDropdownMenu(
      {super.key, required ValueNotifier<ClassLocation> classLocationFilterNotifier}) : _classLocationFilterNotifier = classLocationFilterNotifier;

  @override
  Widget build(BuildContext context) {
    return _classLocationDropdownMenu();
  }

  Widget _classLocationDropdownMenu() {
    return YbDropdownMenu.fromList(
      [
        ...ClassLocation.values.map((location) =>
            YbDropdownMenuOption(
                name: "據點 : ${location.name}", value: location)),
      ],
      initialSelection: YbDropdownMenuOption(
          name: "據點 : ${_classLocationFilterNotifier.value.name}",
          value: _classLocationFilterNotifier.value),
      notifier: _classLocationFilterNotifier,
    );
  }

}
