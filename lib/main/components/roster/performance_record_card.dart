import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import '../../../design_system/presentation/components/system_pill_segment.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/enum/performance_rating.dart';
import '../../../domain/enum/excellent_character.dart';
import 'record_text_field.dart';

class PerformanceRecordCard extends StatelessWidget {
  final String studentName;
  final Map<String, dynamic> values;
  final void Function(String, dynamic)? onChanged;
  final VoidCallback? onExpand;
  final String? notice;
  const PerformanceRecordCard(
      {super.key,
      required this.studentName,
      required this.values,
      this.onChanged,
      this.onExpand,
      this.notice});
  static const metrics = {
    'classPerformanceRating': '上課表現',
    'mathPerformanceRating': '數學',
    'chinesePerformanceRating': '國文',
    'englishPerformanceRating': '英文',
    'socialPerformanceRating': '社會',
  };
  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context),
        gap = SystemTheme.of(context).metric('spaceMedium');
    final rawTags = values['excellentCharacters'];
    final tags =
        rawTags is List ? rawTags.whereType<String>().toList() : <String>[];
    final invalidTags =
        rawTags != null && (rawTags is! List || tags.length != rawTags.length);
    final rating = values['performanceRating'];
    final unknownRating = rating != null &&
        !PerformanceRating.values.any((v) => v.name == rating);
    return SystemSectionCard(
        title: studentName,
        icon: Icons.school_outlined,
        action: onExpand == null
            ? null
            : IconButton(
                tooltip: '全螢幕編輯',
                onPressed: onExpand,
                icon: const Icon(Icons.open_in_full)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
              key: ValueKey(values['performanceRating']),
              initialValue: rating?.toString() ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: '整體表現'),
              items: [
                const DropdownMenuItem(value: '', child: Text('未評分')),
                if (unknownRating)
                  DropdownMenuItem(
                      value: rating.toString(), child: Text('待核對：$rating')),
                for (final rating in PerformanceRating.values)
                  DropdownMenuItem(
                      value: rating.name, child: Text(rating.label)),
              ],
              onChanged: onChanged == null
                  ? null
                  : (value) => onChanged!(
                      'performanceRating', value == '' ? null : value)),
          for (final metric in metrics.entries) ...[
            SizedBox(height: gap),
            Text(metric.value,
                style: TextStyle(
                    fontSize: ds.metric('bodySize'),
                    color: ds.color('primaryText'))),
            SizedBox(height: ds.metric('spaceSmall')),
            if (values[metric.key] != null &&
                (values[metric.key] is! int ||
                    (values[metric.key] as int) < 1 ||
                    (values[metric.key] as int) > 5))
              Text('舊值待核對：${values[metric.key]}'),
            SystemPillSegment<int?>(
                dense: true,
                selected: values[metric.key] is int ? values[metric.key] : null,
                options: [
                  const SystemPillOption(value: null, label: '未評'),
                  for (var score = 1; score <= 5; score++)
                    SystemPillOption(value: score, label: '$score'),
                ],
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged!(metric.key, value)),
          ],
          SizedBox(height: gap),
          RecordTextField(
              value: values['remarks']?.toString() ?? '',
              label: '備註',
              onChanged: onChanged == null
                  ? null
                  : (value) => onChanged!('remarks', value)),
          SizedBox(height: gap),
          if (invalidTags) const Text('舊品格標籤格式待核對，原始值已保留。'),
          Wrap(
              spacing: ds.metric('spaceSmall'),
              runSpacing: ds.metric('spaceSmall'),
              children: [
                for (final tag in ExcellentCharacter.values)
                  FilterChip(
                      label: Text(tag.label),
                      selected: tags.contains(tag.name),
                      onSelected: onChanged == null
                          ? null
                          : (selected) {
                              final next = [...tags];
                              if (selected) {
                                next.add(tag.name);
                              } else {
                                next.remove(tag.name);
                              }
                              onChanged!('excellentCharacters', next);
                            })
              ]),
          if (notice != null)
            Padding(
                padding: EdgeInsets.only(top: gap / 2),
                child: Text(notice!,
                    style: TextStyle(
                        fontSize: ds.metric('labelSize'),
                        color: ds.color('secondaryText')))),
        ]));
  }
}
