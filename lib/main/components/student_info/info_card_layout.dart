import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class InfoCardLayoutWith2Column extends StatelessWidget with YbToolbox {
  final String title;
  final List<Widget> columns1;
  final List<Widget> columns2;

  const InfoCardLayoutWith2Column(
      {super.key,
      required this.title,
      required this.columns1,
      required this.columns2});

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
              child: text(title,
                  size: FlutterFlowTheme.of(context).textTitleSize.h),
            ),
            Divider(
              thickness: 2.h,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: columns1,
                  ),
                ),
                Gap( FlutterFlowTheme.of(context).spaceMedium.h),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: columns2),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Padding _infoCardLayout(BuildContext context,
      {required String title,
      required List<Widget> column1,
      required List<Widget> column2}) {
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
              child: text(title,
                  size: FlutterFlowTheme.of(context).textTitleSize.h),
            ),
            Divider(
              thickness: 2.h,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: column1,
                  ),
                ),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: column2),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class InfoCardLayoutWith1Column extends StatelessWidget with YbToolbox {
  final String title;
  final List<Widget> columns1;
  final Widget? titleSuffix;

  const InfoCardLayoutWith1Column({
    super.key,
    required this.title,
    required this.columns1,
    this.titleSuffix,
  });

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: text(title,
                        size: FlutterFlowTheme.of(context).textTitleSize.h),
                  ),
                ),
                if (titleSuffix != null) titleSuffix!,
              ],
            ),
            Divider(
              thickness: 2.h,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: columns1,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Padding _infoCardLayout(BuildContext context,
      {required String title,
      required List<Widget> column1,
      }) {
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
              child: text(title,
                  size: FlutterFlowTheme.of(context).textTitleSize.h),
            ),
            Divider(
              thickness: 2.h,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: column1,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
