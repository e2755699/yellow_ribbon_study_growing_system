import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_page_header.dart';
import '../../../design_system/presentation/components/system_pill_segment.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/bloc/student_cubit/student_cubit.dart';
import '../../../domain/model/student/student_detail.dart';

/// Real directory layout with injected data/actions; no service initialization.
class StudentDirectoryView extends StatefulWidget {
  const StudentDirectoryView(
      {super.key,
      required this.state,
      required this.onCreate,
      required this.onRetry,
      this.title = '學生名冊',
      this.subtitle = '一起看見，每一位學生的成長。',
      this.onSearch,
      this.onLocation,
      this.onIncludeArchived,
      required this.itemBuilder});
  final StudentsState state;
  final String title, subtitle;
  final VoidCallback? onCreate;
  final VoidCallback onRetry;
  final ValueChanged<String>? onSearch, onLocation;
  final ValueChanged<bool>? onIncludeArchived;
  final Widget Function(StudentDetail student, bool compact) itemBuilder;
  @override
  State<StudentDirectoryView> createState() => _StudentDirectoryViewState();
}

class _StudentDirectoryViewState extends State<StudentDirectoryView> {
  final _searchController = TextEditingController();
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
    final query = widget.state.search;
    final inLocation = widget.state.inLocation;
    final students = widget.state.visibleStudents;
    final locationName = widget.state.sites
            .where((s) => s.id == widget.state.locationId)
            .firstOrNull
            ?.name ??
        '全部據點';
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1080
          ? 3
          : constraints.maxWidth >= 680
              ? 2
              : 1;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return CustomScrollView(
          key: const PageStorageKey('student-directory'),
          slivers: [
            // 共用頁首：標題、主操作與篩選（與每日出席／表現、成長報告一致）。
            SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.only(top: gap / 2),
              child: SystemPageHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  action: widget.onCreate == null
                      ? null
                      : ElevatedButton.icon(
                          onPressed: widget.onCreate,
                          icon: const Icon(Icons.add_rounded),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(44, 52),
                              padding: EdgeInsets.symmetric(
                                  horizontal: gap * 1.25, vertical: gap)),
                          label: const Text('新增學生資料')),
                  filterFlex: const [
                    3,
                    1
                  ],
                  filters: [
                    TextField(
                        controller: _searchController,
                        onChanged: widget.onSearch,
                        style: TextStyle(
                            fontSize: ds.metric('bodySize'),
                            color: ds.color('primaryText')),
                        decoration: InputDecoration(
                            hintText: '搜尋學生姓名或學校',
                            prefixIcon: Icon(Icons.search_rounded,
                                color: ds.color('secondaryText')),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: '清除搜尋',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.onSearch?.call('');
                                    }),
                            contentPadding: EdgeInsets.all(gap))),
                    DropdownButtonFormField<String>(
                        key: ValueKey(widget.state.locationId),
                        initialValue: widget.state.locationId,
                        isExpanded: true,
                        decoration: InputDecoration(
                            labelText: '據點',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: gap, vertical: gap)),
                        items: [
                          const DropdownMenuItem(
                              value: '', child: Text('全部據點')),
                          for (final place in widget.state.sites)
                            DropdownMenuItem(
                                value: place.id, child: Text(place.name))
                        ],
                        onChanged: widget.onLocation == null
                            ? null
                            : (value) => widget.onLocation!(value ?? '')),
                  ]),
            )),
            SliverToBoxAdapter(
                child: SystemPageInfoBar(
              label: widget.state.isLoading
                  ? '正在載入學生資料…'
                  : widget.state.errorMessage != null
                      ? '學生資料暫時無法顯示'
                      : '$locationName  ·  ${students.length} 位學生${query.isEmpty ? '' : ' / 共 ${inLocation.length} 位'}',
              trailing: Wrap(spacing: gap, runSpacing: gap / 2, children: [
                FilterChip(
                    label: const Text('包含已離班學生'),
                    selected: widget.state.includeArchived,
                    onSelected: widget.onIncludeArchived),
                SystemPillSegment<bool>(
                  dense: true,
                  selected: _listView,
                  onChanged: (value) => setState(() => _listView = value),
                  options: const [
                    SystemPillOption(
                        value: false,
                        label: '卡片',
                        icon: Icons.grid_view_rounded),
                    SystemPillOption(
                        value: true,
                        label: '列表',
                        icon: Icons.view_list_rounded),
                  ],
                )
              ]),
            )),
            ..._results(context, students, query, columns, scale),
            SliverToBoxAdapter(child: SizedBox(height: gap)),
          ]);
    });
  }

  List<Widget> _results(BuildContext context, List<StudentDetail> students,
      String query, int columns, double scale) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    if (widget.state.isLoading) {
      return const [
        SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()))
      ];
    }
    if (widget.state.errorMessage != null) {
      return [
        SliverFillRemaining(
            hasScrollBody: false,
            child: _status(Icons.cloud_off_rounded, widget.state.errorMessage!,
                action: OutlinedButton(
                    onPressed: widget.onRetry, child: const Text('重新載入'))))
      ];
    }
    if (students.isEmpty) {
      return [
        SliverFillRemaining(
            hasScrollBody: false,
            child: _status(
                Icons.person_search_rounded,
                query.isNotEmpty
                    ? '找不到符合搜尋條件的學生'
                    : widget.state.students.isEmpty
                        ? '目前沒有學生資料，請使用「新增學生資料」建立。'
                        : '此據點目前沒有學生，請切換其他據點。',
                action: query.isEmpty
                    ? null
                    : OutlinedButton(
                        onPressed: () => setState(_searchController.clear),
                        child: const Text('清除搜尋'))))
      ];
    }
    if (_listView) {
      return [
        SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: gap * .75),
                    child: widget.itemBuilder(students[index], true)),
                childCount: students.length))
      ];
    }
    return [
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
              (context, index) => widget.itemBuilder(students[index], false),
              childCount: students.length)),
    ];
  }

  Widget _status(IconData icon, String message, {Widget? action}) {
    final ds = SystemTheme.of(context);
    return Padding(
        padding: EdgeInsets.all(ds.metric('spaceMedium')),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // 狀態插圖：品牌淺色圓底，讓空／錯誤狀態有溫度而不只是一行灰字。
          Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: ds.surfaceTone(100), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: ds.brandTone(700))),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: ds.metric('bodySize'),
                  color: ds.color('secondaryText'))),
          if (action != null) ...[const SizedBox(height: 12), action],
        ]));
  }
}
