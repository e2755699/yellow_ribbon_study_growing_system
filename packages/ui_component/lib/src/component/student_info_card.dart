import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ui_component/src/component/yr_button.dart';
import 'package:ui_component/src/component/yr_text.dart';
import 'package:ui_component/ui_component.dart';

class StudentInfoCard extends StatelessWidget {
  const StudentInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 360,
        height: 80,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: context.read<YrThemeCubit>().state.theme.color.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: context
                  .read<YrThemeCubit>()
                  .state
                  .theme
                  .color
                  .primaryColor, // 邊框顏色設定為灰色
              width: 2, // 邊框寬度設定為 2 (根據需求調整)
            ),
          ),
        ),
        child: Container(
          width: 400,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: ShapeDecoration(
                  color: context
                      .read<YrThemeCubit>()
                      .state
                      .theme
                      .color
                      .text
                      .defaulted,
                  shape: OvalBorder(),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: context
                          .read<YrThemeCubit>()
                          .state
                          .theme
                          .color
                          .secondaryColor,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    child: YrText(
                      '王小名',
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    child: YrText(
                      '勝利國小三年級',
                    ),
                  ),
                ],
              ),
              YrButton(text: "View", onPressed: (){}),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: ShapeDecoration(
                  color: context
                      .read<YrThemeCubit>()
                      .state
                      .theme
                      .color
                      .secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: YrText(
                  'view',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
