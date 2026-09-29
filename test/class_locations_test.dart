import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/class_locations_cubit/class_locations_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/contracts/class_location_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/memory_class_location_repository.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/class_location_filter_field.dart';

class _FailingRepository implements ClassLocationRepository {
  @override
  Stream<List<ClassLocation>> watch() => Stream.error(StateError('offline'));
}

void main() {
  const yongkang = ClassLocation('台南永康區');
  const north = ClassLocation('台南北區');

  test('cubit reflects every list pushed by the repository', () async {
    final repo = MemoryClassLocationRepository([yongkang]);
    final cubit = ClassLocationsCubit(repo)..watch();
    addTearDown(cubit.close);
    expect(cubit.state.locations, isNull);
    await pumpEventQueue();
    expect(cubit.state.locations, [yongkang]);
    repo.set([yongkang, north]);
    await pumpEventQueue();
    expect(cubit.state.locations, [yongkang, north]);
  });

  test('cubit exposes an error when the list cannot be read', () async {
    final cubit = ClassLocationsCubit(_FailingRepository())..watch();
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.locations, isNull);
    expect(cubit.state.errorMessage, isNotNull);
  });

  Future<void> pumpField(WidgetTester tester, ValueNotifier<ClassLocation?> n,
      {required bool allowAll}) {
    return tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ClassLocationFilterField(
                notifier: n,
                locations: const [yongkang, north],
                allowAll: allowAll))));
  }

  testWidgets('allowAll adds 全部據點 and selecting it clears the filter',
      (tester) async {
    final notifier = ValueNotifier<ClassLocation?>(yongkang);
    await pumpField(tester, notifier, allowAll: true);
    await tester.tap(find.byType(ClassLocationFilterField));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ClassLocationFilterField.allLabel).last);
    await tester.pumpAndSettle();
    expect(notifier.value, isNull);
  });

  testWidgets('without allowAll only live locations are offered',
      (tester) async {
    final notifier = ValueNotifier<ClassLocation?>(yongkang);
    await pumpField(tester, notifier, allowAll: false);
    await tester.tap(find.byType(ClassLocationFilterField));
    await tester.pumpAndSettle();
    expect(find.text(ClassLocationFilterField.allLabel), findsNothing);
    await tester.tap(find.text(north.name).last);
    await tester.pumpAndSettle();
    expect(notifier.value, north);
  });

  testWidgets('a selection missing from the live list still renders',
      (tester) async {
    final notifier = ValueNotifier<ClassLocation?>(const ClassLocation('台南內門'));
    await pumpField(tester, notifier, allowAll: false);
    expect(tester.takeException(), isNull);
    expect(find.text('台南內門'), findsOneWidget);
  });
}
