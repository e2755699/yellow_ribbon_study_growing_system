import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/design_system_editor.dart';
import '../domain/theme_definition.dart';
import 'system_theme.dart';

/// Shared editor used by the application and the isolated Widgetbook gallery.
/// The host owns the editor and repository; this screen never accesses Firebase.
class DesignSystemDashboard extends StatefulWidget {
  const DesignSystemDashboard({super.key, this.onExit, this.sandbox = false});
  final VoidCallback? onExit;
  final bool sandbox;
  @override
  State<DesignSystemDashboard> createState() => DesignSystemDashboardState();
}

class DesignSystemDashboardState extends State<DesignSystemDashboard> {
  int section = 0;
  bool previewDark = false;
  int _selectorGeneration = 0;
  static const sections = [
    'Colors 色彩',
    'Typography 字級',
    'Layout 間距與圓角',
    'Components 元件'
  ];
  static const icons = [
    Icons.palette_outlined,
    Icons.text_fields,
    Icons.space_dashboard_outlined,
    Icons.widgets_outlined
  ];
  DesignSystemEditor get editor => context.read<DesignSystemEditor>();
  Future<bool> confirmExit() => _confirmDiscard();

  Future<void> _nameTheme({required bool create}) async {
    if (create && !await _confirmDiscard()) return;
    if (!mounted || editor.state.saving) return;
    final controller =
        TextEditingController(text: create ? '' : editor.state.draft.name);
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(create ? '新增主題' : '重新命名主題'),
              content: Form(
                  key: form,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (create)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                              '以「${editor.state.baseline.name}」的已儲存設定為起點。每套主題都有自己的明亮／深色配色，可以持續新增。')),
                    TextFormField(
                        key: const Key('theme-name-input'),
                        controller: controller,
                        autofocus: true,
                        maxLength: 40,
                        decoration: const InputDecoration(labelText: '主題名稱'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '請輸入主題名稱'
                                : value.trim().length > 40
                                    ? '名稱最多 40 字'
                                    : null),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: Text(create ? '建立草稿' : '套用名稱'))
              ],
            ));
    if (name != null && mounted) {
      if (create) {
        editor.discard();
        editor.create(name);
      } else {
        editor.rename(name);
      }
      setState(() => _selectorGeneration++);
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (editor.state.saving) return false;
    if (!editor.state.dirty) return true;
    return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('放棄尚未儲存的變更？'),
                  content: const Text('此處的預覽還沒有套用到正式主題。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('繼續編輯')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('放棄變更'))
                  ],
                )) ??
        false;
  }

  Future<void> _editColor(bool dark, String key, String value) async {
    final controller = TextEditingController(text: value);
    final form = GlobalKey<FormState>();
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('${dark ? 'Dark' : 'Light'} · $key'),
              content: Form(
                  key: form,
                  child: TextFormField(
                    key: const Key('token-hex-input'),
                    controller: controller,
                    autofocus: true,
                    maxLength: 7,
                    decoration: const InputDecoration(
                        labelText: 'HEX 色碼', hintText: '#C86B3C'),
                    validator: (text) => RegExp(r'^#[0-9a-fA-F]{6}$')
                            .hasMatch(text?.trim() ?? '')
                        ? null
                        : '請輸入 # 加上 6 位十六進位色碼',
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: const Text('套用預覽'))
              ],
            ));
    if (result != null && mounted) editor.color(dark, key, result);
    // Let the route finish its dismissal before disposing its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF171C20),
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC86B3C), brightness: Brightness.dark),
        ),
        child: Builder(
            builder: (context) =>
                BlocBuilder<DesignSystemEditor, DesignSystemEditorState>(
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      leading: widget.onExit == null
                          ? null
                          : IconButton(
                              tooltip: '返回首頁',
                              icon: const Icon(Icons.arrow_back),
                              onPressed: widget.onExit),
                      title: const Text('Design System',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      actions: [
                        Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Center(
                                child: Text(
                                    widget.sandbox
                                        ? 'Widgetbook Sandbox'
                                        : 'Yellow Ribbon',
                                    style: const TextStyle(fontSize: 12))))
                      ],
                    ),
                    body: LayoutBuilder(builder: (context, size) {
                      final wide = size.maxWidth >= 1000;
                      final navigation = ListView(children: [
                        const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('THEME SETTINGS',
                                style: TextStyle(
                                    fontSize: 12, letterSpacing: 1.5))),
                        for (var i = 0; i < sections.length; i++)
                          ListTile(
                              selected: section == i,
                              leading: Icon(icons[i]),
                              title: Text(sections[i],
                                  style: const TextStyle(fontSize: 14)),
                              onTap: () => setState(() => section = i)),
                      ]);
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (wide) SizedBox(width: 224, child: navigation),
                            Expanded(
                                child: ListView(
                                    key: const Key('design-system-scroll'),
                                    padding: EdgeInsets.all(
                                        size.maxWidth < 600 ? 16 : 28),
                                    children: [
                                  if (!wide)
                                    SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(children: [
                                          for (var i = 0;
                                              i < sections.length;
                                              i++)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: ChoiceChip(
                                                    label: SizedBox(
                                                        width: 145,
                                                        child: Text(sections[i],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        14))),
                                                    selected: section == i,
                                                    onSelected: (_) => setState(
                                                        () => section = i))),
                                        ])),
                                  const SizedBox(height: 20),
                                  Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        SizedBox(
                                            width: 210,
                                            child:
                                                DropdownButtonFormField<String>(
                                              key: ValueKey(
                                                  '${state.draft.id}-$_selectorGeneration'),
                                              value: state.draft.id,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                  labelText: '編輯主題',
                                                  border: OutlineInputBorder()),
                                              items: [
                                                for (final theme
                                                    in editor.themes)
                                                  DropdownMenuItem(
                                                      value: theme.id,
                                                      child: Text(
                                                          theme.id ==
                                                                  state.draft.id
                                                              ? state.draft.name
                                                              : theme.name,
                                                          overflow: TextOverflow
                                                              .ellipsis))
                                              ],
                                              onChanged: state.saving
                                                  ? null
                                                  : (id) async {
                                                      if (id != null &&
                                                          id !=
                                                              state.draft.id &&
                                                          await _confirmDiscard() &&
                                                          mounted) {
                                                        editor.discard();
                                                        editor.select(id);
                                                      }
                                                      if (mounted) {
                                                        setState(() =>
                                                            _selectorGeneration++);
                                                      }
                                                    },
                                            )),
                                        OutlinedButton.icon(
                                            key: const Key('create-theme'),
                                            onPressed: state.saving
                                                ? null
                                                : () =>
                                                    _nameTheme(create: true),
                                            icon: const Icon(Icons.add),
                                            label: const Text('新增主題')),
                                        IconButton(
                                            tooltip: '重新命名主題',
                                            onPressed: state.saving
                                                ? null
                                                : () =>
                                                    _nameTheme(create: false),
                                            icon: const Icon(
                                                Icons.edit_outlined)),
                                        Text(state.isNew
                                            ? '新主題 · 尚未儲存'
                                            : 'v${state.baseline.revision}  ·  ${state.dirty ? '尚未儲存' : state.baseline.revision == 0 ? '內建預設' : '已同步'}'),
                                        OutlinedButton.icon(
                                            onPressed: (state.dirty ||
                                                        state.conflict) &&
                                                    !state.saving
                                                ? () async {
                                                    if (await _confirmDiscard() &&
                                                        mounted) {
                                                      editor.discard();
                                                    }
                                                  }
                                                : null,
                                            icon: const Icon(Icons.restore),
                                            label: Text(state.conflict
                                                ? '重新載入'
                                                : '還原變更')),
                                        FilledButton.icon(
                                            key: const Key('publish-theme'),
                                            onPressed: state.canPublish &&
                                                    state.dirty &&
                                                    !state.saving &&
                                                    !state.conflict &&
                                                    editor.store.loaded &&
                                                    state.draft.validationErrors
                                                        .isEmpty
                                                ? editor.publish
                                                : null,
                                            icon: Icon(state.saving
                                                ? Icons.hourglass_top
                                                : Icons.cloud_upload_outlined),
                                            label: Text(state.saving
                                                ? '儲存中…'
                                                : widget.sandbox
                                                    ? '儲存至沙盒'
                                                    : '儲存共用主題')),
                                      ]),
                                  const SizedBox(height: 16),
                                  _notice(widget.sandbox
                                      ? '沙盒資料只保留於本次 Widgetbook 工作階段，不會寫入 Firebase。'
                                      : state.canPublish
                                          ? '變更先在下方預覽；儲存後才會同步給使用這個主題的人。'
                                          : '預覽模式：你可以調整所有 token；儲存共用主題需要管理端授予的權限。'),
                                  if (editor.store.loadError != null)
                                    _notice(editor.store.loadError!),
                                  if (editor.store.loadError != null)
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                            onPressed: state.saving
                                                ? null
                                                : () async {
                                                    await editor.store.retry();
                                                    await editor.initialize();
                                                  },
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('重新連線'))),
                                  if (state.conflict)
                                    _notice('雲端有較新的版本。你的草稿仍保留；請重新載入後再編輯。'),
                                  if (state.message != null)
                                    _notice(state.message!),
                                  for (final error
                                      in state.draft.validationErrors)
                                    _notice(error),
                                  const SizedBox(height: 20),
                                  Text(sections[section],
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text([
                                    '語意化色彩 token，同時定義明亮與深色模式。點擊色票修改 HEX。',
                                    '共用文字層級，以邏輯像素定義字級。',
                                    '共用間距、圓角與互動狀態。',
                                    '使用實際 Flutter 元件，檢查同一組 token 的呈現。'
                                  ][section]),
                                  const SizedBox(height: 24),
                                  if (section == 0) ...[
                                    _colorPanel(state, false),
                                    const SizedBox(height: 24),
                                    _colorPanel(state, true)
                                  ],
                                  if (section == 1 || section == 2)
                                    _metrics(state),
                                  const SizedBox(height: 24),
                                  Row(children: [
                                    const Expanded(
                                        child: Text('Live Preview 即時預覽',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600))),
                                    const Text('Dark'),
                                    Switch(
                                        value: previewDark,
                                        onChanged: (v) =>
                                            setState(() => previewDark = v))
                                  ]),
                                  const SizedBox(height: 12),
                                  DesignSystemPreview(
                                      definition: state.draft,
                                      dark: previewDark),
                                  const SizedBox(height: 32),
                                ])),
                          ]);
                    }),
                  ),
                )),
      );

  Widget _notice(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style: const TextStyle(color: Color(0xFFEBC8A9), height: 1.5)));

  Widget _colorPanel(DesignSystemEditorState state, bool dark) {
    final colors = dark ? state.draft.dark : state.draft.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF13171A),
          border: Border.all(color: const Color(0xFF354049)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(dark ? 'Dark Mode Theme' : 'Light Mode Theme',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        for (final group in ThemeDefinition.colorGroups.entries) ...[
          Text(group.key, style: const TextStyle(color: Color(0xFFAFBDC7))),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, box) {
            final columns = (box.maxWidth / 155).floor().clamp(1, 6);
            final width = (box.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final key in group.value)
                SizedBox(
                    width: width,
                    child: OutlinedButton(
                      key: Key('${dark ? 'dark' : 'light'}-$key'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: state.saving
                          ? null
                          : () => _editColor(dark, key, colors[key]!),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 44,
                                decoration: BoxDecoration(
                                    color: tokenColor(colors[key]!),
                                    borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 8),
                            Text(key,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            Text(colors[key]!,
                                style: const TextStyle(
                                    color: Color(0xFFAFBDC7), fontSize: 12)),
                          ]),
                    ))
            ]);
          }),
          const SizedBox(height: 20),
        ],
      ]),
    );
  }

  Widget _metrics(DesignSystemEditorState state) => Column(children: [
        for (final entry in ThemeDefinition.metricRanges.entries)
          if (section == 1
              ? entry.key.endsWith('Size')
              : !entry.key.endsWith('Size'))
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${entry.key}  ·  ${state.draft.metrics[entry.key]!.toStringAsFixed(entry.key.endsWith('Darken') ? 2 : 0)}'),
                      Slider(
                          value: state.draft.metrics[entry.key]!
                              .clamp(entry.value.$1, entry.value.$2),
                          min: entry.value.$1,
                          max: entry.value.$2,
                          divisions: entry.key.endsWith('Darken')
                              ? 4
                              : (entry.value.$2 - entry.value.$1).round(),
                          onChanged: state.saving
                              ? null
                              : (value) => editor.metric(entry.key, value)),
                    ])),
      ]);
}

class DesignSystemPreview extends StatelessWidget {
  const DesignSystemPreview(
      {super.key, required this.definition, this.dark = false});
  final ThemeDefinition definition;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final tokens = SystemTheme(definition, dark);
    return Theme(
        data: tokens.materialTheme(),
        child: Builder(
            builder: (context) => Container(
                  padding: EdgeInsets.all(tokens.metric('spaceMedium')),
                  decoration: BoxDecoration(
                      color: tokens.color('primaryBackground'),
                      borderRadius:
                          BorderRadius.circular(tokens.metric('radiusMedium'))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('每一天，都看見成長',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Text('學生資料',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('記錄學習與出席，一起累積小小的進步。',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('預覽範例 · 不會新增學生資料',
                            style: Theme.of(context).textTheme.labelMedium),
                        SizedBox(height: tokens.metric('spaceMedium')),
                        Wrap(
                            spacing: tokens.metric('spaceSmall'),
                            runSpacing: tokens.metric('spaceSmall'),
                            children: [
                              ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.people_outline),
                                  label: const Text('學生資料')),
                              OutlinedButton(
                                  onPressed: () {}, child: const Text('每日出席')),
                              for (final key in [
                                'success',
                                'error',
                                'warning',
                                'info'
                              ])
                                Chip(
                                    label: Text(key),
                                    avatar: Icon(Icons.circle,
                                        color: tokens.color(key), size: 16)),
                            ]),
                        SizedBox(height: tokens.metric('spaceMedium')),
                        const TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                                labelText: '學生姓名', hintText: '文字欄位預覽')),
                      ]),
                )));
  }
}
