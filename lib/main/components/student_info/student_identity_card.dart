import 'package:flutter/material.dart';
import '../../../domain/model/student/student_detail.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../avatar/student_avatar.dart';
import '../yellow_ribbon/yellow_ribbon_count_badge.dart';

/// Presentation-only student card/row, used by both App and Widgetbook.
class StudentIdentityCard extends StatelessWidget {
  const StudentIdentityCard(
      {super.key,
      required this.student,
      required this.onOpen,
      required this.onEdit,
      required this.onDelete,
      this.ribbonCount,
      this.compact = false});
  final StudentDetail student;
  final int? ribbonCount;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final student = this.student;
    final gap = ds.metric('spaceMedium');
    final radius = ds.cardRadius;
    final school = student.school.trim().isEmpty ? '尚未填寫學校' : student.school;
    final menu = PopupMenuButton<String>(
      tooltip: '${student.name}的更多操作',
      icon: Icon(Icons.more_horiz_rounded, color: ds.color('secondaryText')),
      constraints: const BoxConstraints(minWidth: 160),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else {
          onDelete();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('編輯資料')
            ])),
        PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded,
                  size: 20, color: ds.color('error')),
              const SizedBox(width: 12),
              Text('刪除學生', style: TextStyle(color: ds.color('error')))
            ])),
      ],
    );
    final ribbon = YellowRibbonCountBadge(count: ribbonCount);
    final avatar = StudentAvatar(
        avatarFileName: student.avatar,
        gender: student.gender,
        size: compact ? 52 : 64,
        backgroundColor: ds.color('secondary'));
    final name = Text(student.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize:
                compact ? ds.metric('bodySize') + 2 : ds.metric('titleSize'),
            fontWeight: FontWeight.w700,
            color: ds.color('primaryText')));
    final metaStyle = TextStyle(
        fontSize: ds.metric('labelSize'), color: ds.color('secondaryText'));

    return Material(
      color: ds.color('secondaryBackground'),
      shape: RoundedRectangleBorder(borderRadius: radius, side: ds.cardBorder),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        hoverColor: ds.primary.withOpacity(ds.metric('hoverDarken')),
        highlightColor: ds.primary.withOpacity(ds.metric('pressedDarken')),
        child: Padding(
          padding: EdgeInsets.all(gap * 1.25),
          child: compact
              ? LayoutBuilder(
                  builder: (context, box) => Row(children: [
                        avatar,
                        SizedBox(width: gap),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              name,
                              const SizedBox(height: 6),
                              Text('${student.gender} · $school',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: metaStyle),
                              if (box.maxWidth < 650) ...[
                                const SizedBox(height: 4),
                                Text(student.classLocation, style: metaStyle)
                              ],
                            ])),
                        if (box.maxWidth >= 650) ...[
                          SizedBox(width: gap),
                          Text(student.classLocation, style: metaStyle),
                          SizedBox(width: gap * 2),
                          ribbon
                        ],
                        menu,
                      ]))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    avatar,
                    SizedBox(width: gap),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          name,
                          SizedBox(height: gap / 2),
                          Text(
                              student.gender.isEmpty
                                  ? '性別未填'
                                  : '${student.gender}生',
                              style: metaStyle),
                        ])),
                    menu
                  ]),
                  SizedBox(height: gap * 1.25),
                  Row(children: [
                    Icon(Icons.school_outlined,
                        size: 18, color: ds.color('secondaryText')),
                    SizedBox(width: gap / 2),
                    Expanded(
                        child: Text(school,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: ds.metric('bodySize'),
                                color: ds.color('secondaryText'))))
                  ]),
                  const Spacer(),
                  Divider(
                      height: gap * 1.5,
                      color: ds.color('border').withOpacity(.35)),
                  Row(children: [
                    Expanded(
                        child: Text(student.classLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle)),
                    ribbon,
                    SizedBox(width: gap / 2),
                    Icon(Icons.arrow_forward_rounded,
                        size: 18, color: ds.color('detail'))
                  ]),
                ]),
        ),
      ),
    );
  }
}
