import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/record_merge.dart';

void main() {
  const base = {'sid': 'a', 'remarks': '', 'score': 3};
  test('different fields preserve remote edits and unknown legacy fields', () {
    expect(
        mergeRecord(
            recordId: 'a',
            base: base,
            current: {...base, 'score': 5, 'legacyFlag': true},
            submitted: {...base, 'remarks': 'local'}),
        {'sid': 'a', 'remarks': 'local', 'score': 5, 'legacyFlag': true});
  });
  test('same field conflicts instead of overwriting', () {
    expect(
        () => mergeRecord(
            recordId: 'a',
            base: base,
            current: {...base, 'remarks': 'remote'},
            submitted: {...base, 'remarks': 'local'}),
        throwsA(isA<RecordConflict>()));
  });
  test('retry of an already committed patch is idempotent', () {
    final saved = {...base, 'remarks': 'local'};
    expect(
        mergeRecord(
            recordId: 'a', base: base, current: saved, submitted: saved),
        saved);
  });
  test('status and leave reason conflict as one semantic unit', () {
    const base = {'status': 'leave', 'leaveReason': 'a'};
    expect(
        () => mergeRecord(recordId: 'a', base: base, current: {
              ...base,
              'leaveReason': 'remote'
            }, submitted: {
              'status': 'attend',
              'leaveReason': ''
            }, atomicGroups: [
              {'status', 'leaveReason'}
            ]),
        throwsA(isA<RecordConflict>()));
  });
}
