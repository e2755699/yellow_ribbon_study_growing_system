import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class InfoCardLayoutWith2Column extends StatelessWidget {
  const InfoCardLayoutWith2Column(
      {super.key,
      required this.title,
      required this.columns1,
      required this.columns2});
  final String title;
  final List<Widget> columns1;
  final List<Widget> columns2;

  @override
  Widget build(BuildContext context) => _InfoCard(
        title: title,
        child: LayoutBuilder(builder: (context, constraints) {
          final styled = Theme.of(context).extension<SystemTheme>() != null;
          final first = columns1
              .map((field) => styled
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16), child: field)
                  : field)
              .toList();
          final second = columns2
              .map((field) => styled
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16), child: field)
                  : field)
              .toList();
          if (constraints.maxWidth < 640) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...first, const SizedBox(height: 16), ...second]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: first)),
            const SizedBox(width: 24),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: second)),
          ]);
        }),
      );
}

class InfoCardLayoutWith1Column extends StatelessWidget {
  const InfoCardLayoutWith1Column(
      {super.key,
      required this.title,
      required this.columns1,
      this.titleSuffix});
  final String title;
  final List<Widget> columns1;
  final Widget? titleSuffix;

  @override
  Widget build(BuildContext context) => _InfoCard(
      title: title,
      titleSuffix: titleSuffix,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: columns1));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child, this.titleSuffix});
  final String title;
  final Widget child;
  final Widget? titleSuffix;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (Theme.of(context).extension<SystemTheme>() != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SystemSectionCard(
          title: title,
          icon: switch (title) {
            '個人檔案' => Icons.folder_open_rounded,
            '法定代理人或監護人' => Icons.people_alt_rounded,
            '緊急聯絡人' => Icons.phone_in_talk_rounded,
            '學生簡介' => Icons.menu_book_rounded,
            _ => Icons.description_rounded,
          },
          action: titleSuffix,
          child: child,
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.secondary,
          borderRadius: BorderRadius.circular(theme.radiusMedium)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 22,
                          color: theme.primaryText,
                          fontWeight: FontWeight.w600)),
                  if (titleSuffix != null) titleSuffix!,
                ]),
            Divider(height: 24, color: theme.primaryText),
            child,
          ]),
    );
  }
}
