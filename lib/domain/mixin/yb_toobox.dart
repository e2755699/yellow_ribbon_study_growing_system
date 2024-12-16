import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/class_location_dropdown_menu.dart';

mixin YbToolbox{
  Widget tabSection(ValueNotifier<ClassLocation> classLocationFilterNotifier , {List<Widget> Function()? operators}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        ClassLocationDropdownMenu(classLocationFilterNotifier : classLocationFilterNotifier),
        ...operators?.call() ?? [],
        //todo save要把資料存到db
        // SaveButton(),
      ],
    );
  }

}
