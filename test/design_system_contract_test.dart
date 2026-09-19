import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog =
      jsonDecode(File('docs/design-system-components.json').readAsStringSync())
          as Map;
  final components = catalog['components'] as List;
  test('every registered product component is a real generated Widgetbook case',
      () {
    final generated = File('widgetbook_gallery/lib/main.directories.g.dart')
        .readAsStringSync();
    final cases =
        File('widgetbook_gallery/lib/usecases/student_components.dart')
            .readAsStringSync();
    for (final component in components) {
      final name = component['name'];
      expect(File(component['source'] as String).existsSync(), isTrue);
      expect(generated, contains("name: '$name'"),
          reason: '$name must be registered');
      expect(cases, contains('type: $name'),
          reason: 'Use the production class');
      for (final label in component['cases'] as List) {
        expect(generated, contains("name: '$label'"),
            reason: '$name: missing $label');
      }
    }
  });
  test(
      'migrated visuals cannot reintroduce a separate palette or backend reads',
      () {
    for (final component in components) {
      final source = File(component['source'] as String).readAsStringSync();
      expect(source, isNot(contains('StudentProfileTheme')));
      expect(RegExp(r'Color\(0x[0-9a-fA-F]+\)').hasMatch(source), isFalse,
          reason: '${component['name']}: use semantic tokens');
      if (component['name'] != 'StudentAvatar') {
        // Avatar has an injected StorageService for photo loading; it is tested
        // offline with a fake. Business data must stay in page adapters.
        expect(source, isNot(contains('FirebaseFirestore')));
        expect(source, isNot(contains('GetIt.')));
      }
    }
    for (final path in catalog['migratedPages'] as List) {
      final source = File(path as String).readAsStringSync();
      expect(source, contains('SystemThemeScope'));
      expect(source, contains('SystemPage('));
      expect(source, isNot(contains('StudentProfileTheme')));
    }
  });
  test('new public system components require a catalog entry', () {
    final names = components.map((c) => c['name']).toSet();
    for (final file in Directory('lib/design_system/presentation/components')
        .listSync(recursive: true)
        .whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match
          in RegExp(r'class (\w+) extends (?:StatelessWidget|StatefulWidget)')
              .allMatches(file.readAsStringSync())) {
        expect(names, contains(match[1]),
            reason: 'Register ${match[1]} and its Widgetbook cases');
      }
    }
  });
}
