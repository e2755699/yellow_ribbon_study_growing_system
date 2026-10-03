import 'package:flutter/material.dart';
import '../../../domain/model/roster/roster_models.dart';
import '../../../design_system/presentation/system_theme.dart';

/// Shared fields; adapters own the site stream, picker and save command.
class EnrollmentFields extends StatelessWidget {
  final List<ClassSite> sites;
  final String locationId, locationName, dateLabel;
  final bool creating, startKnown, busy;
  final ValueChanged<String>? onLocation;
  final VoidCallback? onDate, onManage;
  const EnrollmentFields(
      {super.key,
      required this.sites,
      required this.locationId,
      required this.locationName,
      required this.dateLabel,
      this.creating = false,
      this.startKnown = true,
      this.busy = false,
      this.onLocation,
      this.onDate,
      this.onManage});
  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (creating)
        DropdownButtonFormField<String>(
          key: ValueKey('site-$locationId'),
          isExpanded: true,
          initialValue:
              sites.any((s) => s.id == locationId) ? locationId : null,
          decoration: const InputDecoration(labelText: '據點（必填）'),
          items: [
            for (final site in sites.where((s) => s.active))
              DropdownMenuItem(value: site.id, child: Text(site.name))
          ],
          onChanged: busy || onLocation == null
              ? null
              : (id) {
                  if (id != null) onLocation!(id);
                },
          validator: (value) => value == null ? '請選擇據點' : null,
        )
      else
        Text('據點：$locationName',
            style: TextStyle(fontSize: ds.metric('bodySize'))),
      SizedBox(height: ds.metric('spaceSmall')),
      if (creating)
        OutlinedButton.icon(
            onPressed: busy ? null : onDate,
            icon: const Icon(Icons.calendar_month),
            label: Text('入班日期：$dateLabel'))
      else
        Text(startKnown ? '入班日期：$dateLabel' : '已確認在班起點：$dateLabel（實際入班日待核對）'),
      if (creating)
        Text('出席率從入班日起的實際上課日開始計算。',
            style: TextStyle(
                color: ds.color('secondaryText'),
                fontSize: ds.metric('labelSize'))),
      if (onManage != null)
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: busy ? null : onManage,
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('就讀異動／核對歷史入班日'))),
    ]);
  }
}
