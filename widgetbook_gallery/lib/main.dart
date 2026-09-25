import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';
import 'gallery_environment.dart';

void main() {
  runApp(const WidgetbookGallery());
}

@widgetbook.App()
class WidgetbookGallery extends StatelessWidget {
  const WidgetbookGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryEnvironment(
        child: Widgetbook.material(
      directories: directories,
    ));
  }
}
