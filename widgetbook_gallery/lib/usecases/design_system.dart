import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_editor.dart';
import '../gallery_environment.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/design_system_dashboard.dart';

@widgetbook.UseCase(name: 'Theme Settings', type: DesignSystemDashboard)
Widget themeSettings(BuildContext context) => const _Sandbox();

@widgetbook.UseCase(
    name: 'Four palettes · Light & Dark', type: DesignSystemPreview)
Widget palettes(BuildContext context) =>
    ListView(padding: const EdgeInsets.all(24), children: [
      for (final theme in defaultDesignThemes()) ...[
        Text(theme.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        DesignSystemPreview(definition: theme),
        const SizedBox(height: 12),
        DesignSystemPreview(definition: theme, dark: true),
        const SizedBox(height: 32),
      ],
    ]);

class _Sandbox extends StatefulWidget {
  const _Sandbox();
  @override
  State<_Sandbox> createState() => _SandboxState();
}

class _SandboxState extends State<_Sandbox> {
  DesignSystemEditor? _editor;
  DesignSystemEditor get editor => _editor!;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _editor ??= DesignSystemEditor(GalleryEnvironment.storeOf(context))
      ..initialize();
  }

  @override
  void dispose() {
    editor.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
      value: editor, child: const DesignSystemDashboard(sandbox: true));
}
