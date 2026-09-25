import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_store.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/data/memory_design_system_repository.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';

class GalleryEnvironment extends StatefulWidget {
  const GalleryEnvironment({super.key, required this.child});
  final Widget child;
  @override
  State<GalleryEnvironment> createState() => _GalleryEnvironmentState();
  static DesignSystemStore storeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GalleryStore>()!.notifier!;
}

class _GalleryEnvironmentState extends State<GalleryEnvironment> {
  final repository = MemoryDesignSystemRepository();
  late final store = DesignSystemStore(repository)..start();
  @override
  void dispose() {
    store.dispose();
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _GalleryStore(
      store: store,
      child: DefaultAssetBundle(bundle: _ProductAssets(), child: widget.child));
}

class _GalleryStore extends InheritedNotifier<DesignSystemStore> {
  const _GalleryStore({required DesignSystemStore store, required super.child})
      : super(notifier: store);
}

// Product assets are packaged under the dependency name by Flutter. Keep
// product widgets identical in App and Widgetbook rather than copying images.
class _ProductAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key.startsWith('assets/')
      ? 'packages/yellow_ribbon_study_growing_system/$key'
      : key);
}

class ProductPreview extends StatefulWidget {
  const ProductPreview({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  State<ProductPreview> createState() => _ProductPreviewState();
}

class _ProductPreviewState extends State<ProductPreview> {
  bool dark = false;
  double width = 1024;
  @override
  Widget build(BuildContext context) {
    final store = GalleryEnvironment.storeOf(context);
    final theme = SystemTheme(store.active, dark);
    return Theme(
        data: theme.materialTheme(),
        child: Builder(
            builder: (context) => Scaffold(
                backgroundColor: theme.color('secondary'),
                body: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DropdownButton<String>(
                                value: store.active.id,
                                items: [
                                  for (final definition in store.themes)
                                    DropdownMenuItem(
                                        value: definition.id,
                                        child: Text(definition.name))
                                ],
                                onChanged: (id) {
                                  if (id != null) store.select(id);
                                }),
                            OutlinedButton.icon(
                                onPressed: () => setState(() => dark = !dark),
                                icon: Icon(dark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined),
                                label: Text(dark ? 'Dark' : 'Light')),
                            DropdownButton<double>(
                                value: width,
                                items: [
                                  for (final size in [
                                    507.0,
                                    768.0,
                                    1024.0,
                                    1194.0
                                  ])
                                    DropdownMenuItem(
                                        value: size,
                                        child: Text('${size.toInt()} px'))
                                ],
                                onChanged: (value) =>
                                    setState(() => width = value!)),
                          ])),
                  Expanded(
                      child: Center(
                          child: SizedBox(
                              width: width,
                              child: Builder(builder: widget.builder)))),
                ]))));
  }
}

void previewAction(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
