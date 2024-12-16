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


  Text text(String data, {Color? color, double? size}) {
    return Text(
      data,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
    );
  }

  BoxDecoration buildBoxDecoration(double radius, Color color) {
    return BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      color: color,
    );
  }

}
