import 'package:flutter/material.dart';
import '../../../domain/model/roster/roster_models.dart';
import '../../../design_system/presentation/system_theme.dart';

class EnrollmentChangeRequest {
  final String mode, locationId, reason;
  final BusinessDate date, endDate;
  final String? enrollmentId;
  const EnrollmentChangeRequest(this.mode, this.locationId, this.date,
      this.endDate, this.reason, this.enrollmentId);
}

/// The same production form is used in the management dialog and Widgetbook.
class EnrollmentChangeForm extends StatefulWidget {
  final List<ClassSite> sites;
  final List<Enrollment> periods;
  final String currentLocationId;
  final ValueChanged<EnrollmentChangeRequest> onSubmit;
  final VoidCallback onCancel;
  const EnrollmentChangeForm(
      {super.key,
      required this.sites,
      required this.periods,
      required this.currentLocationId,
      required this.onSubmit,
      required this.onCancel});
  @override
  State<EnrollmentChangeForm> createState() => _EnrollmentChangeFormState();
}

class _EnrollmentChangeFormState extends State<EnrollmentChangeForm> {
  String mode = 'transfer';
  String? locationId, periodId;
  BusinessDate date = BusinessDate.today(), end = BusinessDate('9999-12-31');
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> pick(bool ending) async {
    final selected = ending && end.value == '9999-12-31'
        ? BusinessDate.today()
        : ending
            ? end
            : date;
    final value = await showDatePicker(
        context: context,
        initialDate: selected.calendar,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (value != null && mounted) {
      setState(() {
        if (ending) {
          end = BusinessDate.fromCalendar(value);
        } else {
          date = BusinessDate.fromCalendar(value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = SystemTheme.of(context).metric('spaceMedium');
    return Form(
        key: form,
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              DropdownButtonFormField<String>(
                  initialValue: mode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '異動類型'),
                  items: const [
                    DropdownMenuItem(value: 'transfer', child: Text('轉換據點')),
                    DropdownMenuItem(value: 'archive', child: Text('離班／封存')),
                    DropdownMenuItem(value: 'reenroll', child: Text('重新入班')),
                    DropdownMenuItem(value: 'correct', child: Text('核對歷史就讀期間')),
                  ],
                  onChanged: (v) => setState(() => mode = v!)),
              SizedBox(height: gap),
              if (mode == 'transfer' || mode == 'reenroll')
                DropdownButtonFormField<String>(
                    key: const ValueKey('enrollment-location'),
                    initialValue: locationId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '生效據點'),
                    items: [
                      for (final site in widget.sites.where((s) => s.active))
                        DropdownMenuItem(value: site.id, child: Text(site.name))
                    ],
                    validator: (v) => v == null
                        ? '請選擇據點'
                        : mode == 'transfer' && v == widget.currentLocationId
                            ? '請選擇不同的據點'
                            : null,
                    onChanged: (v) => setState(() => locationId = v)),
              if (mode == 'correct')
                DropdownButtonFormField<String>(
                    key: const ValueKey('enrollment-period'),
                    initialValue: periodId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '核對的就讀期間'),
                    items: [
                      for (final period in widget.periods)
                        DropdownMenuItem(
                            value: period.id,
                            child: Text(
                                '${widget.sites.where((s) => s.id == period.locationId).firstOrNull?.name ?? '待核對據點'} · ${period.startDate}',
                                overflow: TextOverflow.ellipsis))
                    ],
                    validator: (v) => v == null ? '請選擇就讀期間' : null,
                    onChanged: (v) => setState(() {
                          periodId = v;
                          final period =
                              widget.periods.firstWhere((p) => p.id == v);
                          date = period.startDate;
                          end = period.endDateExclusive;
                        })),
              SizedBox(height: gap),
              OutlinedButton.icon(
                  onPressed: () => pick(false),
                  icon: const Icon(Icons.calendar_month),
                  label: Text('${mode == 'correct' ? '開始日期' : '生效日期'}：$date')),
              if (mode == 'correct') ...[
                SizedBox(height: gap),
                OutlinedButton(
                    onPressed: () => pick(true),
                    child: Text(
                        '離班首日：${end.value == '9999-12-31' ? '仍在班' : end.value}')),
                TextButton(
                    onPressed: () =>
                        setState(() => end = BusinessDate('9999-12-31')),
                    child: const Text('設為仍在班')),
                TextFormField(
                    controller: reason,
                    maxLength: 400,
                    decoration: const InputDecoration(labelText: '核對依據／原因（必填）'),
                    validator: (v) => v == null || v.trim().length < 3
                        ? '至少 3 字，請記下核對依據'
                        : null),
              ],
              SizedBox(height: gap),
              Text(mode == 'archive'
                  ? '選定日期起不再列入名冊；先前出席、表現與緞帶仍保留。'
                  : mode == 'correct'
                      ? '開始含當日，離班首日不含當日。更正會影響對應期間的出席率分母，請依已確認資料填寫。'
                      : '選定日期起使用新的就讀關係；之前的紀錄維持原據點。'),
              SizedBox(height: gap),
              Wrap(alignment: WrapAlignment.end, spacing: gap, children: [
                TextButton(onPressed: widget.onCancel, child: const Text('返回')),
                FilledButton(
                    onPressed: () {
                      if (!form.currentState!.validate()) return;
                      if (mode == 'correct' && date.compareTo(end) >= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('離班首日必須晚於開始日期')));
                        return;
                      }
                      widget.onSubmit(EnrollmentChangeRequest(
                          mode,
                          locationId ?? widget.currentLocationId,
                          date,
                          end,
                          reason.text.trim(),
                          periodId));
                    },
                    child: const Text('確認異動')),
              ]),
            ])));
  }
}
