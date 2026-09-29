import 'package:flutter/material.dart';
import '../system_theme.dart';

/// 頁首色塊：標題、說明、主操作與篩選列的共同版型。
///
/// 背景為 `SystemTheme.headerGradient`（只由主題背景 token 組成）；
/// 篩選列內的輸入欄位統一為白色、無外框，與色塊形成對比。
/// 名冊、每日出席、每日表現、成長報告共用，確保篩選與主操作位置一致。
class SystemPageHeader extends StatelessWidget {
  const SystemPageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.action,
      this.filters = const [],
      this.filterFlex});
  final String title;
  final String? subtitle;

  /// 本頁主操作（新增、儲存），固定在右上。
  final Widget? action;

  /// 篩選欄位（據點、日期、搜尋）；寬版同列排列，窄版堆疊。
  final List<Widget> filters;

  /// 各篩選欄位的寬度比例；未提供時平均分配。
  final List<int>? filterFlex;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    final theme = Theme.of(context);
    final fieldBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(ds.metric('radiusSmall')),
        borderSide: BorderSide.none);
    return Container(
      padding: EdgeInsets.all(gap * 1.25),
      decoration: BoxDecoration(
          borderRadius: ds.cardRadius,
          border: Border.fromBorderSide(ds.cardBorder),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ds.headerGradient)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: ds.metric('headingSize'),
                            fontWeight: FontWeight.w700,
                            color: ds.color('primaryText'))),
                    if (subtitle != null) ...[
                      SizedBox(height: gap / 2),
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: ds.metric('bodySize'),
                              fontWeight: FontWeight.w600,
                              color: ds.brandTone(700))),
                    ],
                  ]),
              if (action != null) action!,
            ]),
        if (filters.isNotEmpty) ...[
          SizedBox(height: gap * 1.25),
          Theme(
            data: theme.copyWith(
                inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                    filled: true,
                    fillColor: ds.color('secondaryBackground'),
                    border: fieldBorder,
                    enabledBorder: fieldBorder)),
            child: LayoutBuilder(builder: (context, box) {
              if (box.maxWidth < 600) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) SizedBox(height: gap),
                        filters[i],
                      ]
                    ]);
              }
              return Row(children: [
                for (var i = 0; i < filters.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(flex: filterFlex?[i] ?? 1, child: filters[i]),
                ]
              ]);
            }),
          ),
        ],
      ]),
    );
  }
}

/// 頁首下方的資訊列：左側範圍說明（據點、人數），右側補充控制（檢視切換、統計）。
class SystemPageInfoBar extends StatelessWidget {
  const SystemPageInfoBar({super.key, required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return Padding(
      padding: EdgeInsets.only(top: gap * 1.25, bottom: gap),
      child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: gap,
          runSpacing: gap / 2,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: ds.metric('labelSize'),
                    fontWeight: FontWeight.w600,
                    color: ds.color('secondaryText'))),
            if (trailing != null) trailing!,
          ]),
    );
  }
}
