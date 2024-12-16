import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class PersonalInfoCard extends StatelessWidget with YbToolbox {
  const PersonalInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(FlutterFlowTheme.of(context).spaceXLarge.h),
      child: Container(
        decoration: buildBoxDecoration(
            FlutterFlowTheme.of(context).radiusMedium,
            FlutterFlowTheme.of(context).secondary),
        padding: EdgeInsets.all(FlutterFlowTheme.of(context).spaceXLarge.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: text("個人資訊",
                  size: FlutterFlowTheme.of(context).textTitleSize.h),
            ),
            Divider(
              thickness: 2.h,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      text("姓名 : 王小明",
                          size: FlutterFlowTheme.of(context).textBody1Size.h),
                      text("型別 : 男",
                          size: FlutterFlowTheme.of(context).textBody1Size.h),
                      text("出生年月 : 1987/09/03",
                          size: FlutterFlowTheme.of(context).textBody1Size.h),
                      text("身份字號 : D121921731",
                          size: FlutterFlowTheme.of(context).textBody1Size.h),
                      text("血型 : O型",
                          size: FlutterFlowTheme.of(context).textBody1Size.h),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        text("住址 : 台南市永康區忠孝路385號",
                            size: FlutterFlowTheme.of(context).textBody1Size.h),
                        text("手機 : 0928778673",
                            size: FlutterFlowTheme.of(context).textBody1Size.h),
                        text("家用電話 : 062234644",
                            size: FlutterFlowTheme.of(context).textBody1Size.h),
                        text("電子郵件 : e2755699@gmail.com",
                            size: FlutterFlowTheme.of(context).textBody1Size.h),
                        text("學校 : 勝利國小",
                            size: FlutterFlowTheme.of(context).textBody1Size.h),
                        text("是否需要接送 : 否",
                            size: FlutterFlowTheme.of(context).textBody1Size.h),
                      ]),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
