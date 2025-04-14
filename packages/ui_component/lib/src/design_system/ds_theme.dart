import 'package:flutter/material.dart';

enum DsTheme{
  light(color: DsColor.light),
  dark(color : DsColor.dark);

  final DsColor color;

  const DsTheme({required this.color});
}

enum DsColor{
  light(primaryColor: Color(0xFFF5CC00), secondaryColor : Color(0xFFF3E9C0)),
  dark(primaryColor: Color(0xFF292200), secondaryColor : Color(0xFFF3E9C0));

  const DsColor({required this.primaryColor,required this.secondaryColor});
  final Color primaryColor;
  final Color secondaryColor;
}