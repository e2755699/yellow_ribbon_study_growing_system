import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
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

  Widget deleteButton(BuildContext context,{ required VoidCallback onPressed}) {
    return TextButton.icon(
        icon: Icon(
          Icons.delete_forever_sharp,
          color: FlutterFlowTheme.of(context).error,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext _) {
              return AlertDialog(
                title: const Text('確認刪除'),
                content: const Text('確定要刪除這筆資料嗎？此操作無法恢復。'),
                actions: [
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: onPressed,
                    child: const Text('確認'),
                  ),
                ],
              );
            },
          );
        },

        // onPressed: () {
        //   context.read<StudentsCubit>().deleteStudent(student.id!);
        // },
        label: Text(
          "刪除",
          style: TextStyle(color: FlutterFlowTheme.of(context).error),
        ));
  }

  TextButton editButton(BuildContext context, { required VoidCallback onPressed}) {
    return TextButton.icon(
        icon: Icon(Icons.edit, color: FlutterFlowTheme.of(context).primary),
        onPressed: onPressed,
        label: Text(
          "編輯",
          style: TextStyle(color: FlutterFlowTheme.of(context).primary),
        ));
  }


}
