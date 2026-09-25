import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/bloc/student_cubit/student_cubit.dart';
import '../../../domain/enum/class_location.dart';
import '../../../domain/model/student/student_detail.dart';

/// Real directory layout with injected data/actions; no service initialization.
class StudentDirectoryView extends StatefulWidget {
  const StudentDirectoryView(
      {super.key,
      required this.state,
      required this.onCreate,
      required this.onRetry,
      required this.itemBuilder});
  final StudentsState state;
  final VoidCallback onCreate;
  final VoidCallback onRetry;
  final Widget Function(StudentDetail student, bool compact) itemBuilder;
  @override
  State<StudentDirectoryView> createState() => _StudentDirectoryViewState();
}

class _StudentDirectoryViewState extends State<StudentDirectoryView> {
  final _searchController = TextEditingController();
  String _location = ClassLocation.values.first.name;
  bool _listView = false;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: _content(context)));

  Widget _content(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    final query = _searchController.text.trim().toLowerCase();
    final inLocation = widget.state.students
        .where((s) => _location.isEmpty || s.classLocation == _location)
        .toList();
    final students = inLocation
        .where((s) =>
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.school.toLowerCase().contains(query))
        .toList();
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 650;
      final columns = constraints.maxWidth >= 1080
          ? 3
          : constraints.maxWidth >= 680
              ? 2
              : 1;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return CustomScrollView(
          key: const PageStorageKey('student-directory'),
          slivers: [
            SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.only(top: gap / 2, bottom: gap * 1.5),
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('學生名冊',
                              style: TextStyle(
                                  fontSize: ds.metric('headingSize'),
                                  fontWeight: FontWeight.w700,
                                  color: ds.color('primaryText'))),
                          SizedBox(height: gap / 2),
                          Text('一起看見，每一位學生的成長。',
                              style: TextStyle(
                                  fontSize: ds.metric('bodySize'),
                                  color: ds.color('secondaryText'))),
                        ]),
                    ElevatedButton.icon(
                        onPressed: widget.onCreate,
                        icon: const Icon(Icons.add_rounded),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: ds.primary,
                            foregroundColor: ds.onPrimary,
                            minimumSize: const Size(44, 52),
                            elevation: 0,
                            textStyle: TextStyle(
                                fontSize: ds.metric('buttonSize'),
                                fontWeight: FontWeight.w700),
                            padding: EdgeInsets.symmetric(
                                horizontal: gap * 1.25, vertical: gap),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    ds.metric('radiusSmall')))),
                        label: const Text('新增學生資料')),
                  ]),
            )),
            SliverToBoxAdapter(
                child: Container(
              padding: EdgeInsets.all(gap),
              decoration: BoxDecoration(
                  color: ds.color('secondaryBackground'),
                  border: Border.all(color: ds.color('border').withOpacity(.4)),
                  borderRadius:
                      BorderRadius.circular(ds.metric('radiusMedium'))),
              child: LayoutBuilder(builder: (context, toolbar) {
                final search = TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        fontSize: ds.metric('bodySize'),
                        color: ds.color('primaryText')),
                    decoration: InputDecoration(
                        hintText: '搜尋學生姓名或學校',
                        hintStyle: TextStyle(color: ds.color('secondaryText')),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: ds.color('secondaryText')),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '清除搜尋',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () =>
                                    setState(_searchController.clear)),
                        filled: true,
                        fillColor: ds.color('secondary'),
                        contentPadding: EdgeInsets.all(gap),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(ds.metric('radiusSmall')),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(ds.metric('radiusSmall')),
                            borderSide: BorderSide.none)));
                final location = DropdownButtonFormField<String>(
                    value: _location,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: '據點',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: gap, vertical: gap)),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('全部據點')),
                      for (final place in ClassLocation.values)
                        DropdownMenuItem(
                            value: place.name, child: Text(place.name))
                    ],
                    onChanged: (value) =>
                        setState(() => _location = value ?? ''));
                return narrow
                    ? Column(
                        children: [search, SizedBox(height: gap), location])
                    : Row(children: [
                        Expanded(child: search),
                        SizedBox(width: gap),
                        SizedBox(width: 220, child: location)
                      ]);
              }),
            )),
            SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: gap),
                    child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: gap,
                        runSpacing: gap / 2,
                        children: [
                          Text(
                              widget.state.isLoading
                                  ? '正在載入學生資料…'
                                  : widget.state.errorMessage != null
                                      ? '學生資料暫時無法顯示'
                                      : '${_location.isEmpty ? '全部據點' : _location}  ·  ${students.length} 位學生${query.isEmpty ? '' : ' / 共 ${inLocation.length} 位'}',
                              style: TextStyle(
                                  fontSize: ds.metric('labelSize'),
                                  color: ds.color('secondaryText'))),
                          ToggleButtons(
                              isSelected: [!_listView, _listView],
                              onPressed: (index) =>
                                  setState(() => _listView = index == 1),
                              constraints: const BoxConstraints(
                                  minWidth: 96, minHeight: 44),
                              borderRadius: BorderRadius.circular(
                                  ds.metric('radiusSmall')),
                              borderColor: ds.color('border').withOpacity(.5),
                              selectedBorderColor: ds.color('border'),
                              fillColor: ds.brandSurface,
                              selectedColor: ds.color('primaryText'),
                              color: ds.color('secondaryText'),
                              textStyle: TextStyle(
                                  fontSize: ds.metric('labelSize'),
                                  fontWeight: FontWeight.w600),
                              children: const [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.grid_view_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('卡片')
                                ]),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.view_list_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('列表')
                                ])
                              ]),
                        ]))),
            if (widget.state.isLoading)
              const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()))
            else if (widget.state.errorMessage != null)
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: _status(
                      Icons.cloud_off_rounded, widget.state.errorMessage!,
                      action: ElevatedButton(
                          onPressed: widget.onRetry,
                          child: const Text('重新載入'))))
            else if (students.isEmpty)
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: _status(
                      Icons.person_search_rounded,
                      query.isNotEmpty
                          ? '找不到符合搜尋條件的學生'
                          : widget.state.students.isEmpty
                              ? '目前沒有學生資料，請使用「新增學生資料」建立。'
                              : '$_location目前沒有學生，請切換其他據點。',
                      action: query.isEmpty
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  setState(_searchController.clear),
                              child: const Text('清除搜尋'))))
            else if (_listView)
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                          padding: EdgeInsets.only(bottom: gap / 2),
                          child: widget.itemBuilder(students[index], true)),
                      childCount: students.length))
            else
              SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                      mainAxisExtent: (118 +
                              ds.metric('titleSize') * 2 +
                              ds.metric('labelSize') * 2 +
                              gap * 2) *
                          scale),
                  delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          widget.itemBuilder(students[index], false),
                      childCount: students.length)),
            SliverToBoxAdapter(child: SizedBox(height: gap)),
          ]);
    });
  }

  Widget _status(IconData icon, String message, {Widget? action}) {
    final ds = SystemTheme.of(context);
    return Padding(
        padding: EdgeInsets.all(ds.metric('spaceMedium')),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: ds.color('secondaryText')),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: ds.color('secondaryText'))),
          if (action != null) ...[const SizedBox(height: 12), action],
        ]));
  }
}
