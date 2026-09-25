import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../design_system/presentation/components/system_section_card.dart';

class StudentProfileOverview extends StatelessWidget {
  const StudentProfileOverview(
      {super.key,
      required this.student,
      required this.activity,
      required this.ribbonCount,
      required this.onEdit,
      required this.onHistory,
      required this.onRetry,
      required this.attachment});
  final StudentDetail student;
  final StudentActivityState activity;
  final int ribbonCount;
  final VoidCallback onEdit;
  final VoidCallback? onHistory;
  final VoidCallback onRetry;
  final Widget attachment;

  String _value(String? value) =>
      value == null || value.trim().isEmpty ? '尚未填寫' : value;
  String _date(DateTime value) => DateFormat('yyyy/MM/dd').format(value);

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('student-profile-overview'),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _hero(context),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium')),
          _summaries(context),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium')),
          LayoutBuilder(builder: (context, constraints) {
            final basic = SystemSectionCard(
              title: '基本資料',
              icon: Icons.description_rounded,
              child: _fields(context, [
                ('生日', _date(student.birthday)),
                ('性別', student.gender),
                ('學校', student.school),
                ('聯絡電話', student.phone),
              ]),
            );
            final recent = SystemSectionCard(
              title: '近期表現',
              icon: Icons.star_rounded,
              action: _historyLink(context),
              child: _recent(context),
            );
            if (constraints.maxWidth < 760) {
              return Column(children: [
                basic,
                SizedBox(height: SystemTheme.of(context).metric('spaceMedium')),
                recent
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: basic),
              SizedBox(width: SystemTheme.of(context).metric('spaceMedium')),
              Expanded(child: recent),
            ]);
          }),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium')),
          SystemSectionCard(
              title: '學習足跡',
              icon: Icons.history_rounded,
              action: _historyLink(context),
              child: _timeline(context)),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium') * 1.5),
          Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text('更認識這位學生',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: SystemTheme.of(context).metric('bodySize')))),
          _details(context, '家庭與聯絡人', Icons.people_alt_rounded, [
            (
              '家庭狀況',
              ['雙親', '單親與父同住', '單親與母同住', '隔代教養'][student.familyStatus.index]
            ),
            ('監護人', student.guardianName),
            ('監護人電話', student.guardianPhone),
            ('監護人電子郵件', student.guardianEmail),
            ('監護人身分證', student.guardianIdNumber),
            ('監護人任職單位', student.guardianCompany),
            ('緊急聯絡人', student.emergencyContactName),
            ('緊急聯絡電話', student.emergencyContactPhone),
            ('緊急聯絡人電子郵件', student.emergencyContactEmail),
            ('緊急聯絡人身分證', student.emergencyContactIdNumber),
            ('緊急聯絡人任職單位', student.emergencyContactCompany),
          ]),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium') * .75),
          _details(context, '學習與照顧需求', Icons.spa_rounded, [
            ('身分證字號', student.idNumber),
            ('電子郵件', student.email),
            ('經濟狀況', ['一般', '中低收入戶', '低收入戶'][student.economicStatus.index]),
            ('族群身分', ['非原住民／新住民', '原住民', '新住民'][student.ethnicStatus.index]),
            ('特殊疾病', student.hasSpecialDisease ? '有' : '無'),
            if (student.hasSpecialDisease)
              ('疾病說明', student.specialDiseaseDescription ?? ''),
            ('特殊學生', student.isSpecialStudent ? '是' : '否'),
            if (student.isSpecialStudent)
              ('需求說明', student.specialStudentDescription ?? ''),
            ('接送需求', student.needsPickup ? '需要接送' : '不需接送'),
            if (student.needsPickup)
              ('接送說明', student.pickupRequirementDescription ?? ''),
            ('興趣', student.interest),
            ('能力評估', student.abilityEvaluation),
            ('學習目標', student.learningGoals),
            ('物資及獎助學金', student.resourcesAndScholarships),
            ('才藝班', student.talentClass),
            ('特殊課程', student.specialCourse),
          ]),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium') * .75),
          _details(context, '學生簡介與觀察', Icons.menu_book_rounded, [
            ('學生簡介', student.studentIntroduction),
            ('表現描述', student.description),
          ]),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium')),
          attachment,
          SizedBox(
              height: SystemTheme.of(context).metric('spaceMedium') * 1.25),
          Center(
              child: Text('陪伴每一步成長，發現每一道光。',
                  style: TextStyle(
                      color: SystemTheme.of(context).color('secondaryText'),
                      fontSize: SystemTheme.of(context).metric('labelSize')))),
        ],
      );

  Widget _hero(BuildContext context) => Container(
        key: const Key('student-profile-hero'),
        decoration: SystemTheme.of(context).cardDecoration,
        padding:
            EdgeInsets.all(SystemTheme.of(context).metric('spaceMedium') * 1.5),
        child: LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 580;
          final avatar = StudentAvatar(
            avatarFileName: student.avatar,
            gender: student.gender,
            size: narrow ? 80 : 112,
            backgroundColor: SystemTheme.of(context).accentSurface,
          );
          final identity = Row(children: [
            avatar,
            SizedBox(width: narrow ? 16 : 24),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_value(student.name),
                      style: TextStyle(
                          fontSize:
                              SystemTheme.of(context).metric('headingSize'),
                          fontWeight: FontWeight.w800,
                          color: SystemTheme.of(context).color('primaryText'),
                          letterSpacing: 1)),
                  SizedBox(
                      height:
                          SystemTheme.of(context).metric('spaceMedium') * .5),
                  _pill(context, student.classLocation,
                      yellow: true, icon: Icons.wb_sunny_rounded),
                  SizedBox(
                      height:
                          SystemTheme.of(context).metric('spaceMedium') * .75),
                  Text('學生檔案',
                      style: TextStyle(
                          fontSize: SystemTheme.of(context).metric('labelSize'),
                          letterSpacing: 2,
                          color:
                              SystemTheme.of(context).color('secondaryText'))),
                  SelectableText(_value(student.id),
                      style: TextStyle(
                          fontSize: SystemTheme.of(context).metric('labelSize'),
                          color:
                              SystemTheme.of(context).color('secondaryText'))),
                ])),
          ]);
          final edit = OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('編輯資料'));
          if (narrow) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  SizedBox(
                      height:
                          SystemTheme.of(context).metric('spaceMedium') * 1.25),
                  _motto(context),
                  SizedBox(
                      height:
                          SystemTheme.of(context).metric('spaceMedium') * 1.25),
                  Align(alignment: Alignment.centerRight, child: edit),
                ]);
          }
          final header = Row(children: [
            Expanded(flex: 5, child: identity),
            if (constraints.maxWidth > 830)
              Expanded(flex: 3, child: _motto(context)),
            SizedBox(
                width: SystemTheme.of(context).metric('spaceMedium') * 1.25),
            edit,
          ]);
          if (constraints.maxWidth > 830) return header;
          return Column(children: [
            header,
            SizedBox(
                height: SystemTheme.of(context).metric('spaceMedium') * 1.25),
            _motto(context),
          ]);
        }),
      );

  Widget _motto(BuildContext context) => Column(children: [
        Icon(Icons.auto_awesome_outlined,
            size: 24, color: SystemTheme.of(context).color('warning')),
        SizedBox(height: SystemTheme.of(context).metric('spaceMedium') * .625),
        Text(
            student.displayMotto == StudentDetail.defaultMotto
                ? StudentDetail.defaultMotto.replaceFirst('，', '，\n')
                : student.displayMotto,
            key: const Key('student-motto'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: SystemTheme.of(context).color('secondaryText'),
                height: 1.8,
                fontSize: SystemTheme.of(context).metric('bodySize'),
                letterSpacing: 3)),
      ]);

  Widget _summaries(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 4 : 2;
        final value = activity.loading
            ? '載入中'
            : activity.failed
                ? '未能載入'
                : activity.records.isEmpty
                    ? '尚無紀錄'
                    : activity
                        .records.first.performanceRatingNotifier.value.label;
        final tiles = [
          _summary(context, Icons.workspace_premium_rounded, '黃絲帶',
              '$ribbonCount 枚', false),
          _summary(context, Icons.star_rounded, '最近一次表現', value, true),
          _summary(
              context,
              Icons.bar_chart_rounded,
              '表現紀錄',
              activity.loading
                  ? '載入中'
                  : activity.failed
                      ? '未能載入'
                      : '${activity.records.length} 筆',
              false),
          _summary(context, Icons.people_alt_rounded, '監護人',
              _value(student.guardianName), true),
        ];
        return Wrap(
            spacing: SystemTheme.of(context).metric('spaceMedium') * .75,
            runSpacing: SystemTheme.of(context).metric('spaceMedium') * .75,
            children: [
              for (final tile in tiles)
                SizedBox(
                    width:
                        (constraints.maxWidth - (columns - 1) * 12) / columns,
                    child: tile),
            ]);
      });

  Widget _summary(BuildContext context, IconData icon, String label,
          String value, bool yellow) =>
      Container(
        decoration: SystemTheme.of(context).cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(children: [
          _icon(context, icon, yellow: yellow),
          SizedBox(width: SystemTheme.of(context).metric('spaceMedium') * .75),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        color: SystemTheme.of(context).color('secondaryText'),
                        fontSize: SystemTheme.of(context).metric('labelSize'))),
                SizedBox(
                    height:
                        SystemTheme.of(context).metric('spaceMedium') * .375),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: SystemTheme.of(context).metric('titleSize'),
                        color: SystemTheme.of(context).color('primaryText'),
                        fontWeight: FontWeight.w700)),
              ])),
        ]),
      );

  Widget _historyLink(BuildContext context) => TextButton(
      onPressed: onHistory,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('查看更多',
            style: TextStyle(
                fontSize: SystemTheme.of(context).metric('labelSize'))),
        const SizedBox(width: 2),
        const Icon(Icons.chevron_right_rounded, size: 16),
      ]));

  Widget? _activityStatus(BuildContext context) {
    if (activity.loading) {
      return const Padding(
          padding: EdgeInsets.all(36),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (activity.failed) {
      return Column(children: [
        Text('暫時無法讀取表現紀錄',
            style: TextStyle(
                color: SystemTheme.of(context).color('secondaryText'))),
        TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重試')),
      ]);
    }
    if (activity.records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          Icon(Icons.spa_outlined,
              color: SystemTheme.of(context).color('detail'), size: 30),
          SizedBox(height: SystemTheme.of(context).metric('spaceMedium') * .75),
          const Text('成長的故事，從每一天開始',
              style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(
              height: SystemTheme.of(context).metric('spaceMedium') * .375),
          Text('目前尚無表現紀錄',
              style: TextStyle(
                  color: SystemTheme.of(context).color('secondaryText'),
                  fontSize: SystemTheme.of(context).metric('labelSize'))),
        ]),
      );
    }
    return null;
  }

  Widget _recent(BuildContext context) =>
      _activityStatus(context) ??
      Column(children: [
        for (final entry in activity.records.take(3).indexed) ...[
          if (entry.$1 > 0)
            Divider(
                height: SystemTheme.of(context).metric('spaceMedium') * 1.25),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _icon(context, Icons.spa_rounded,
                small: true, yellow: entry.$1.isOdd),
            SizedBox(
                width: SystemTheme.of(context).metric('spaceMedium') * .75),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('學習表現',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(
                      entry.$2.remarksNotifier.value.isEmpty
                          ? '這一天尚未填寫文字評語'
                          : entry.$2.remarksNotifier.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: SystemTheme.of(context).metric('labelSize'),
                          height: 1.5,
                          color:
                              SystemTheme.of(context).color('secondaryText'))),
                ])),
            SizedBox(
                width: SystemTheme.of(context).metric('spaceMedium') * .625),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_date(entry.$2.recordDate),
                  style: TextStyle(
                      fontSize: SystemTheme.of(context).metric('labelSize'),
                      color: SystemTheme.of(context).color('secondaryText'))),
              SizedBox(
                  height: SystemTheme.of(context).metric('spaceMedium') * .375),
              _pill(context, entry.$2.performanceRatingNotifier.value.label,
                  yellow: entry.$1.isOdd),
            ]),
          ]),
        ],
      ]);

  Widget _timeline(BuildContext context) =>
      _activityStatus(context) ??
      Column(children: [
        for (final entry in activity.records.take(3).indexed)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.$1.isOdd
                            ? SystemTheme.of(context).color('warning')
                            : SystemTheme.of(context).color('detail'))),
                SizedBox(width: SystemTheme.of(context).metric('spaceMedium')),
                Expanded(
                    child: Wrap(
                        spacing: SystemTheme.of(context).metric('spaceMedium') *
                            1.25,
                        runSpacing:
                            SystemTheme.of(context).metric('spaceMedium') * .5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                      Text(_date(entry.$2.recordDate),
                          style: TextStyle(
                              fontSize:
                                  SystemTheme.of(context).metric('labelSize'),
                              color: SystemTheme.of(context)
                                  .color('secondaryText'))),
                      const Text('學習紀錄',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          entry.$2.excellentCharactersNotifier.value.isEmpty
                              ? '已記錄當日表現'
                              : entry.$2.excellentCharactersNotifier.value
                                  .map((c) => c.label)
                                  .join(' · '),
                          style: TextStyle(
                              fontSize:
                                  SystemTheme.of(context).metric('labelSize'),
                              color: SystemTheme.of(context)
                                  .color('secondaryText'))),
                    ])),
              ])),
      ]);

  Widget _details(BuildContext context, String title, IconData icon,
          List<(String, String)> fields) =>
      Container(
        decoration: SystemTheme.of(context).cardDecoration,
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: SystemTheme.of(context).color('detail'),
              collapsedIconColor: SystemTheme.of(context).color('detail'),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading:
                  Icon(icon, color: SystemTheme.of(context).color('detail')),
              title: Text(title,
                  style: TextStyle(
                      color: SystemTheme.of(context).color('primaryText'),
                      fontWeight: FontWeight.w600,
                      fontSize: SystemTheme.of(context).metric('bodySize'))),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [_fields(context, fields)],
            ),
          ),
        ),
      );

  Widget _fields(BuildContext context, List<(String, String)> fields) =>
      Column(children: [
        for (final entry in fields.indexed) ...[
          if (entry.$1 > 0) const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 110,
                    child: Text(entry.$2.$1,
                        style: TextStyle(
                            color:
                                SystemTheme.of(context).color('secondaryText'),
                            fontSize:
                                SystemTheme.of(context).metric('bodySize')))),
                SizedBox(
                    width: SystemTheme.of(context).metric('spaceMedium') * .75),
                Expanded(
                    child: SelectableText(_value(entry.$2.$2),
                        style: TextStyle(
                            color: SystemTheme.of(context).color('primaryText'),
                            fontSize:
                                SystemTheme.of(context).metric('bodySize'),
                            height: 1.4))),
              ])),
        ],
      ]);

  Widget _icon(BuildContext context, IconData icon,
          {bool yellow = false, bool small = false}) =>
      Container(
        width: small ? 36 : 48,
        height: small ? 36 : 48,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: yellow
                ? SystemTheme.of(context).accentSurface
                : SystemTheme.of(context).brandSurface),
        child: Icon(icon,
            size: small ? 20 : 26,
            color: yellow
                ? SystemTheme.of(context).color('warning')
                : SystemTheme.of(context).color('detail')),
      );

  Widget _pill(BuildContext context, String text,
          {bool yellow = false, IconData? icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                SystemTheme.of(context).metric('radiusSmall')),
            color: yellow
                ? SystemTheme.of(context).accentSurface
                : SystemTheme.of(context).brandSurface),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon,
                size: 17, color: SystemTheme.of(context).color('warning')),
            const SizedBox(width: 7)
          ],
          Flexible(
              child: Text(_value(text),
                  style: TextStyle(
                      fontSize: SystemTheme.of(context).metric('labelSize'),
                      fontWeight: FontWeight.w600,
                      color: yellow
                          ? SystemTheme.of(context).color('primaryText')
                          : SystemTheme.of(context).color('detail')))),
        ]),
      );
}
