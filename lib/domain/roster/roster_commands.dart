import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'roster_command_failure.dart';

typedef RosterMap = Map<String, dynamic>;

/// One invocation must be one database transaction. Reads precede all writes.
abstract class RosterCommandStore {
  Future<T> transaction<T>(Future<T> Function(RosterCommandTransaction) body);
  Object get serverTimestamp;
  Object timestamp(DateTime value);
  DateTime? dateTime(Object? value);
}

abstract class RosterCommandTransaction {
  Future<RosterMap?> get(String path);
  void set(String path, RosterMap data, {bool merge = false});
}

/// Business calculations are deliberately client-owned. Firestore Rules still
/// enforce site access, maintenance, shapes and atomic receipt linkage.
class RosterCommands {
  final RosterCommandStore store;
  final DateTime Function() clock;
  RosterCommands(this.store, {DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  static const ratingFields = [
    'classPerformanceRating',
    'mathPerformanceRating',
    'chinesePerformanceRating',
    'englishPerformanceRating',
    'socialPerformanceRating',
  ];
  static const performanceFields = [
    'performanceRating',
    'remarks',
    'excellentCharacters',
    ...ratingFields,
  ];
  static const profileFields = [
    'name',
    'gender',
    'phone',
    'birthday',
    'idNumber',
    'school',
    'email',
    'economicStatus',
    'guardianName',
    'guardianIdNumber',
    'guardianCompany',
    'guardianPhone',
    'guardianEmail',
    'emergencyContactName',
    'emergencyContactIdNumber',
    'emergencyContactCompany',
    'emergencyContactPhone',
    'emergencyContactEmail',
    'description',
    'hasSpecialDisease',
    'specialDiseaseDescription',
    'isSpecialStudent',
    'specialStudentDescription',
    'needsPickup',
    'pickupRequirementDescription',
    'familyStatus',
    'ethnicStatus',
    'interest',
    'abilityEvaluation',
    'learningGoals',
    'resourcesAndScholarships',
    'talentClass',
    'specialCourse',
    'studentIntroduction',
    'motto',
  ];
  static Never fail(String code) => throw RosterCommandFailure(code);
  static void require(bool condition, [String code = 'invalid-argument']) {
    if (!condition) fail(code);
  }

  static String id(dynamic value) {
    require(
        value is String && RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value));
    return value as String;
  }

  static String date(dynamic value) {
    require(value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value));
    final parsed = DateTime.tryParse(value as String);
    require(
        parsed != null && parsed.toIso8601String().substring(0, 10) == value);
    return value;
  }

  String get today => clock()
      .toUtc()
      .add(const Duration(hours: 8))
      .toIso8601String()
      .substring(0, 10);
  static RosterMap map(dynamic value) {
    require(value is Map);
    return Map<String, dynamic>.from(value as Map);
  }

  static dynamic _stable(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _stable(value[key])};
    }
    if (value is List) return value.map(_stable).toList();
    // Match JSON.stringify's integral-number representation for old receipts.
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt();
    }
    return value;
  }

  static String digest(RosterMap value) =>
      sha256.convert(utf8.encode(jsonEncode(_stable(value)))).toString();
  static void scope(RosterMap access, dynamic loc, {bool manager = false}) {
    require(
        access['active'] == true &&
            ['teacher', 'manager', 'owner'].contains(access['role']) &&
            (!manager || ['manager', 'owner'].contains(access['role'])) &&
            (access['locationIds'] as List? ?? []).contains(loc),
        'permission-denied');
  }

  static void validatePatch(String kind, RosterMap patch) {
    final allowed =
        kind == 'attendance' ? ['status', 'leaveReason'] : performanceFields;
    require(patch.isNotEmpty && patch.keys.every(allowed.contains));
    for (final entry in patch.entries) {
      final k = entry.key, v = entry.value;
      if (k == 'status') {
        require([
          null,
          'attend',
          'absent',
          'leave',
          'late',
          'earlyLeave',
          'busAbsent'
        ].contains(v));
      } else if (k == 'performanceRating') {
        require([null, 'excellent', 'good', 'average', 'poor', 'terrible']
            .contains(v));
      } else if (ratingFields.contains(k)) {
        require(v == null || (v is int && v >= 1 && v <= 5));
      } else if (k == 'excellentCharacters') {
        require(v is List &&
            v.length <= 30 &&
            v.every((x) => x is String && x.length <= 80));
      } else {
        require(v is String && v.length <= 4000);
      }
    }
  }

  static void validateProfile(RosterMap patch) {
    require(patch.keys.every(profileFields.contains));
    for (final entry in patch.entries) {
      final k = entry.key, v = entry.value;
      if (['hasSpecialDisease', 'isSpecialStudent', 'needsPickup']
          .contains(k)) {
        require(v is bool);
      } else if (['economicStatus', 'familyStatus', 'ethnicStatus']
          .contains(k)) {
        require(v is int && v >= 0 && v <= 20);
      } else if (k == 'birthday') {
        require(v is String && DateTime.tryParse(v) != null);
      } else {
        require(v == null || (v is String && v.length <= 10000));
      }
    }
    if (patch.containsKey('name')) {
      require(patch['name'] is String &&
          (patch['name'] as String).trim().isNotEmpty &&
          (patch['name'] as String).length <= 120);
    }
  }

  static RosterMap mergeValues(RosterMap current, RosterMap patch) {
    final next = {...current, ...patch};
    if (patch.containsKey('status') && patch['status'] != 'leave') {
      next['leaveReason'] = '';
    }
    return next;
  }

  RosterMap stamp(String uid, String op) => {
        'updatedBy': uid,
        'updatedAt': store.serverTimestamp,
        'lastOperationId': op,
      };

  Future<RosterMap> execute(String uid, RosterMap input) async {
    // Freeze nested payload before an SDK retry; hash and writes must agree.
    final frozen = map(jsonDecode(jsonEncode(input)));
    if (frozen['action'] == 'recoverOperation') {
      final original = map(frozen['original']);
      final oldId = id(original['operationId']), hash = digest(original);
      return store.transaction((tx) async {
        final access = await tx.get('staff_access/$uid');
        final previous = await tx.get('record_operations/$oldId');
        require(
            access != null && access['active'] == true, 'permission-denied');
        // Missing receipt is not proof that the old Function never committed.
        require(previous != null, 'failed-precondition');
        require(previous!['uid'] == uid && previous['hash'] == hash,
            'already-exists');
        for (final loc in previous['locationIds'] as List? ?? []) {
          scope(access!, loc);
        }
        return map(previous['result']);
      });
    }
    final operationId = id(frozen['operationId']);
    final hash = digest(frozen);
    return store.transaction((tx) async {
      final access = await tx.get('staff_access/$uid');
      final config = await tx.get('app_config/roster');
      final previous = await tx.get('record_operations/$operationId');
      require(access != null && access['active'] == true, 'permission-denied');
      if (previous != null) {
        require(previous['uid'] == uid && previous['hash'] == hash,
            'already-exists');
        for (final loc in previous['locationIds'] as List? ?? []) {
          scope(access!, loc);
        }
        return map(previous['result']);
      }
      require(
          config?['status'] == 'enabled' &&
              config?['clientWritesEnabled'] == true,
          'failed-precondition');
      final RosterMap result;
      switch (frozen['action']) {
        case 'saveRecord':
        case 'saveRecords':
          result = await _save(tx, access!, uid, frozen);
        case 'setSession':
          result = await _session(tx, access!, uid, frozen);
        case 'enrollStudent':
          result = await _enroll(tx, access!, uid, frozen);
        case 'updateProfile':
          result = await _profile(tx, access!, uid, frozen);
        case 'changeEnrollment':
          result = await _membership(tx, access!, uid, frozen, false);
        case 'correctEnrollment':
          result = await _membership(tx, access!, uid, frozen, true);
        case 'redeemRibbon':
          result = await _redeem(tx, access!, uid, frozen);
        default:
          fail('invalid-argument');
      }
      tx.set('record_operations/$operationId', {
        'uid': uid,
        'hash': hash,
        'action': frozen['action'],
        'result': result,
        'locationIds': result['locationIds'] ?? [frozen['locationId']],
        'createdAt': store.serverTimestamp,
      });
      return result;
    });
  }

  Future<RosterMap> _save(RosterCommandTransaction tx, RosterMap access,
      String uid, RosterMap input) async {
    final kind = input['kind'];
    require(kind == 'attendance' || kind == 'performance');
    final loc = id(input['locationId']),
        day = date(input['dateKey']),
        op = id(input['operationId']);
    scope(access, loc);
    require(day.compareTo(today) <= 0);
    final single = input['action'] == 'saveRecord';
    if (!single) require(input['records'] is List);
    final rows =
        single ? [input] : (input['records'] as List).map(map).toList();
    require(rows.isNotEmpty && rows.length <= 100);
    final seen = <String>{};
    for (final row in rows) {
      require(seen.add(id(row['studentId'])));
      validatePatch(kind as String, map(row['patch']));
      if (row['base'] != null) map(row['base']);
    }
    final sessionPath = 'class_sessions/$day.$loc';
    final session = await tx.get(sessionPath);
    require(session?['status'] != 'cancelled', 'failed-precondition');
    final index = await tx.get('membership_indexes/$loc');
    require(index != null, 'failed-precondition');
    final entries = map(index!['entries']);
    final pending = <({String path, RosterMap data, bool merge})>[];
    final results = <String, dynamic>{};
    var holdSession = false;
    for (final row in rows) {
      final sid = id(row['studentId']), recordId = '$day.$loc.$sid';
      final path =
          '${kind == 'attendance' ? 'attendance_records' : 'performance_records'}/$recordId';
      final old = await tx.get(path);
      // Summary preserves historical-site access without reading another site's profile.
      final student = await tx.get('student_summaries/$sid');
      final count = kind == 'performance'
          ? await tx.get('yellow_ribbon_counts/$sid')
          : null;
      final eid = row['enrollmentId'] == null ? null : id(row['enrollmentId']);
      final enrollment = entries[eid];
      final valid = enrollment is Map &&
          enrollment['studentId'] == sid &&
          enrollment['locationId'] == loc &&
          (enrollment['startDate'] as String).compareTo(day) <= 0 &&
          day.compareTo(enrollment['endDateExclusive'] as String) < 0;
      if (!valid) {
        scope(access, loc, manager: true);
        final reason = row['correctionReason'];
        require(old != null &&
            reason is String &&
            reason.trim().length >= 3 &&
            reason.length <= 4000);
      }
      require(student != null || old != null, 'not-found');
      final patch = map(row['patch']), current = map(old?['values'] ?? {});
      final values = mergeValues(current, patch);
      final confirmed = <String>{
        ...List<String>.from(old?['confirmedFields'] ?? []),
        ...patch.keys
      }.toList();
      final provenance = old == null ||
              old['provenance'] == 'confirmed' ||
              (kind == 'attendance'
                  ? confirmed.contains('status')
                  : performanceFields
                      .where((k) => values[k] != null)
                      .every(confirmed.contains))
          ? 'confirmed'
          : 'partiallyConfirmed';
      var active = old?['awardActive'] == true,
          review = old?['awardReviewRequired'] == true;
      if (kind == 'performance') {
        require(count != null,
            'failed-precondition'); // Migration seeds protected wallet ACL.
        final excellent = values['performanceRating'] == 'excellent';
        final wasExcellent = current['performanceRating'] == 'excellent';
        final delta = excellent && !wasExcellent
            ? 1
            : !excellent && wasExcellent && active
                ? -1
                : 0;
        if (!excellent && wasExcellent && !active) review = true;
        if (delta != 0) {
          active = delta > 0;
          pending.add((
            path: 'yellow_ribbon_counts/$sid',
            merge: true,
            data: {
              'totalCount': (count!['totalCount'] as num? ?? 0) + delta,
              'usedCount': count['usedCount'] ?? 0,
              'lastUpdated': store.serverTimestamp,
              'lastOperationId': op,
              'updatedBy': uid,
              'locationId': loc,
              'dateKey': day,
              'enrollmentId': valid ? eid : null,
              if (!valid) 'correctionReason': row['correctionReason'],
            }
          ));
          pending.add((
            path: 'ribbon_events/$op.$sid',
            merge: false,
            data: {
              'studentId': sid,
              'locationId': loc,
              'recordId': recordId,
              'dateKey': day,
              'enrollmentId': valid ? eid : null,
              if (!valid) 'correctionReason': row['correctionReason'],
              'delta': delta,
              'kind': delta > 0 ? 'award' : 'reversal',
              'operationId': op,
              'updatedBy': uid,
              'createdAt': store.serverTimestamp,
            }
          ));
        }
      }
      final revision = (old?['revision'] as int? ?? 0) + 1;
      pending.add((
        path: path,
        merge: true,
        data: {
          'schemaVersion': 2,
          'studentId': sid,
          'locationId': loc,
          'dateKey': day,
          'enrollmentId': valid ? eid : null,
          'nameSnapshot': student?['name'] ?? old?['nameSnapshot'] ?? '歷史學生',
          'revision': revision,
          'values': values,
          'provenance': provenance,
          'confirmedFields': confirmed,
          ...stamp(uid, op),
          if (kind == 'performance') ...{
            'awardActive': active,
            'awardReviewRequired': review
          },
          if (row['correctionReason'] != null)
            'correctionReason': row['correctionReason'],
        }
      ));
      holdSession |= kind == 'attendance' && values['status'] != null;
      results[sid] = {
        'recordId': recordId,
        'revision': revision,
        'values': values,
        'provenance': provenance,
        'confirmedFields': confirmed,
        'awardReviewRequired': review
      };
    }
    final result = single
        ? map(results.values.single)
        : <String, dynamic>{
            'records': results,
            'locationIds': [loc]
          };
    // Leave room for Firestore document overhead in the immutable replay receipt.
    // An oversized class fails as a whole; it is never silently split.
    require(utf8.encode(jsonEncode(result)).length <= 900 * 1024);
    // No writes have occurred until every row has been read and validated.
    for (final write in pending) {
      tx.set(write.path, write.data, merge: write.merge);
    }
    if (holdSession && session?['status'] != 'held') {
      tx.set(
          sessionPath,
          {
            'locationId': loc,
            'dateKey': day,
            'status': 'held',
            'revision': (session?['revision'] as int? ?? 0) + 1,
            ...stamp(uid, op)
          },
          merge: true);
    }
    return result;
  }

  Future<RosterMap> _session(RosterCommandTransaction tx, RosterMap access,
      String uid, RosterMap input) async {
    final loc = id(input['locationId']), day = date(input['dateKey']);
    scope(access, loc, manager: input['status'] == 'cancelled');
    require(['held', 'cancelled'].contains(input['status']) &&
        day.compareTo(today) <= 0);
    if (input['status'] == 'cancelled') {
      require(input['reason'] is String &&
          (input['reason'] as String).trim().length >= 3 &&
          (input['reason'] as String).length <= 400);
    }
    final path = 'class_sessions/$day.$loc', old = await tx.get(path);
    require((old?['revision'] ?? 0) == input['expectedRevision'], 'aborted');
    final revision = (old?['revision'] as int? ?? 0) + 1;
    tx.set(path, {
      'locationId': loc,
      'dateKey': day,
      'status': input['status'],
      'reason': input['reason'] ?? '',
      'revision': revision,
      ...stamp(uid, input['operationId'])
    });
    return {'sessionId': '$day.$loc', 'revision': revision};
  }

  Future<RosterMap> _profile(RosterCommandTransaction tx, RosterMap access,
      String uid, RosterMap input) async {
    map(input['base']);
    final sid = id(input['studentId']), old = await tx.get('students/$sid');
    require(old != null, 'not-found');
    require(old!['enrollmentTimeline'] is List, 'failed-precondition');
    final timeline = (old['enrollmentTimeline'] as List).map(map).toList();
    require(timeline.isNotEmpty, 'failed-precondition');
    final loc = membershipProjection(timeline, today)['locationId'] as String;
    scope(access, loc);
    final patch = map(input['patch']);
    validateProfile(patch);
    require(patch.isNotEmpty);
    final values = {
      for (final k in profileFields)
        k: store.dateTime(old[k])?.toUtc().toIso8601String() ?? old[k]
    };
    final merged = mergeValues(values, patch),
        revision = (old['revision'] as int? ?? 0) + 1;
    final changes = {...patch};
    if (changes.containsKey('birthday')) {
      changes['birthday'] =
          store.timestamp(DateTime.parse(changes['birthday'] as String));
    }
    tx.set('students/$sid',
        {...changes, 'revision': revision, ...stamp(uid, input['operationId'])},
        merge: true);
    if (changes.containsKey('name')) {
      tx.set('student_summaries/$sid', {'name': changes['name']}, merge: true);
    }
    return {
      'studentId': sid,
      'revision': revision,
      'values': merged,
      'locationIds': [loc]
    };
  }

  static RosterMap indexEntry(RosterMap period) => {
        for (final k in [
          'studentId',
          'locationId',
          'startDate',
          'endDateExclusive'
        ])
          k: period[k],
      };
  Future<Map<String, RosterMap>> _indexes(
      RosterCommandTransaction tx, Iterable<String> sites) async {
    final result = <String, RosterMap>{};
    for (final site in sites.toSet()) {
      result[site] = await tx.get('membership_indexes/$site') ??
          {'entries': <String, dynamic>{}};
    }
    return result;
  }

  void _writeIndexes(RosterCommandTransaction tx,
      Map<String, RosterMap> indexes, List<RosterMap> changed) {
    for (final item in indexes.entries) {
      final periods =
          changed.where((p) => p['locationId'] == item.key).toList();
      if (periods.isEmpty) continue;
      tx.set('membership_indexes/${item.key}', {
        'entries': {
          ...map(item.value['entries']),
          for (final p in periods) p['id'] as String: indexEntry(p)
        },
        'changedEnrollmentIds': periods.map((p) => p['id']).toList(),
      });
    }
  }

  Future<RosterMap> _enroll(RosterCommandTransaction tx, RosterMap access,
      String uid, RosterMap input) async {
    final sid = id(input['studentId']),
        loc = id(input['locationId']),
        start = date(input['startDate']),
        op = id(input['operationId']);
    scope(access, loc, manager: true);
    final profile = map(input['profile']);
    validateProfile(profile);
    require(profile['name'] != null &&
        utf8.encode(jsonEncode(profile)).length <= 100000);
    final student = await tx.get('students/$sid'),
        site = await tx.get('class_locations/$loc');
    final indexes = await _indexes(tx, [loc]);
    require(student == null, 'already-exists');
    require(site != null && site['active'] != false);
    final period = {
      'id': op,
      'studentId': sid,
      'locationId': loc,
      'startDate': start,
      'endDateExclusive': '9999-12-31',
      'startKnown': true
    };
    final projection = membershipProjection([period], today);
    tx.set('students/$sid', {
      ...profile,
      if (profile['birthday'] != null)
        'birthday':
            store.timestamp(DateTime.parse(profile['birthday'] as String)),
      'id': sid,
      'classLocation': site!['name'],
      ...projection,
      'enrollmentRevision': 1,
      'revision': 1,
      'enrollmentTimeline': [period],
      'timelineSites': [loc],
      'enrollmentChange': {'kind': 'create', 'index': 0},
      'createdAt': store.serverTimestamp,
      ...stamp(uid, op)
    });
    tx.set('student_enrollments/$op', {
      ...indexEntry(period),
      'startKnown': true,
      'revision': 1,
      'source': 'enrollment',
      ...stamp(uid, op)
    });
    tx.set('student_summaries/$sid', {
      'name': profile['name'],
      'locationIds': [loc],
      'enrollmentTimeline': [period],
      'archived': projection['archived']
    });
    tx.set('yellow_ribbon_counts/$sid', {
      'totalCount': 0,
      'usedCount': 0,
      'locationIds': [loc],
      'lastUpdated': store.serverTimestamp,
      'lastOperationId': op,
      'updatedBy': uid
    });
    _writeIndexes(tx, indexes, [period]);
    return {
      'studentId': sid,
      'enrollmentId': op,
      'revision': 1,
      'locationIds': [loc]
    };
  }

  static RosterMap membershipProjection(List<RosterMap> periods, String day) {
    final sorted = [...periods]..sort((a, b) =>
        (a['startDate'] as String).compareTo(b['startDate'] as String));
    final active = sorted
        .where((p) =>
            (p['startDate'] as String).compareTo(day) <= 0 &&
            day.compareTo(p['endDateExclusive'] as String) < 0)
        .toList();
    require(active.length <= 1);
    final earlier = sorted
        .where((p) => (p['startDate'] as String).compareTo(day) <= 0)
        .toList();
    final selected = active.isNotEmpty
        ? active.first
        : earlier.isNotEmpty
            ? earlier.last
            : sorted.first;
    return {
      'locationId': selected['locationId'],
      'enrollmentStartDate': selected['startDate'],
      'enrollmentStartKnown': selected['startKnown'] != false,
      'archived': active.isEmpty && earlier.isNotEmpty
    };
  }

  Future<RosterMap> _membership(RosterCommandTransaction tx, RosterMap access,
      String uid, RosterMap input, bool correction) async {
    final sid = id(input['studentId']), op = id(input['operationId']);
    final student = await tx.get('students/$sid');
    require(student != null, 'not-found');
    require(
        student!['enrollmentRevision'] == input['expectedRevision'], 'aborted');
    require(student['enrollmentTimeline'] is List, 'failed-precondition');
    final periods = (student['enrollmentTimeline'] as List).map(map).toList();
    require(periods.isNotEmpty, 'failed-precondition');
    final next = periods.map((p) => {...p}).toList(), changed = <RosterMap>[];
    final touched = <String>{};
    late int index;
    late String changeKind;
    if (correction) {
      final eid = id(input['enrollmentId']),
          start = date(input['startDate']),
          end = date(input['endDateExclusive']);
      require(start.compareTo(end) < 0 &&
          input['reason'] is String &&
          (input['reason'] as String).trim().length >= 3 &&
          (input['reason'] as String).length <= 4000);
      index = next.indexWhere((p) => p['id'] == eid);
      require(index >= 0, 'not-found');
      for (final p in periods) {
        scope(access, p['locationId'], manager: true);
        touched.add(p['locationId'] as String);
      }
      require(!periods.any((p) =>
          p['id'] != eid &&
          (p['startDate'] as String).compareTo(end) < 0 &&
          (p['endDateExclusive'] as String).compareTo(start) > 0));
      // Incremental Rules validate the changed slot against its two neighbours.
      require((index == 0 ||
              (next[index - 1]['endDateExclusive'] as String)
                      .compareTo(start) <=
                  0) &&
          (index == next.length - 1 ||
              end.compareTo(next[index + 1]['startDate'] as String) <= 0));
      next[index] = {
        ...next[index],
        'startDate': start,
        'endDateExclusive': end,
        'startKnown': true
      };
      changed.add(next[index]);
      changeKind = 'replace';
    } else {
      final day = date(input['effectiveDate']), mode = input['mode'];
      require(['transfer', 'archive', 'reenroll'].contains(mode));
      final active = next
          .where((p) =>
              (p['startDate'] as String).compareTo(day) <= 0 &&
              day.compareTo(p['endDateExclusive'] as String) < 0)
          .toList();
      require(active.length <= 1);
      final old = active.isEmpty ? null : active.single;
      require(mode == 'reenroll' ? old == null : old != null);
      // Ending a period on its start day would leave an empty period, which
      // the rules reject (startDate < endDateExclusive); stop it here with a
      // clear reason instead of a misleading permission error.
      require(old == null || (old['startDate'] as String).compareTo(day) < 0,
          'same-day-enrollment');
      final loc = mode == 'archive'
          ? old!['locationId'] as String
          : id(input['locationId']);
      scope(access, loc, manager: true);
      touched.add(loc);
      if (old != null) {
        scope(access, old['locationId'], manager: true);
        touched.add(old['locationId'] as String);
      }
      require(!next.any((p) =>
          p['id'] != old?['id'] &&
          (p['endDateExclusive'] as String).compareTo(day) > 0));
      final site = await tx.get('class_locations/$loc');
      require(site != null && site['active'] != false);
      index = old == null
          ? next.length
          : next.indexWhere((p) => p['id'] == old['id']);
      if (old != null) {
        next[index] = {...old, 'endDateExclusive': day};
        changed.add(next[index]);
      }
      if (mode != 'archive') {
        final p = {
          'id': op,
          'studentId': sid,
          'locationId': loc,
          'startDate': day,
          'endDateExclusive': '9999-12-31',
          'startKnown': true
        };
        next.add(p);
        changed.add(p);
      }
      changeKind = mode == 'archive'
          ? 'replace'
          : old == null
              ? 'insert'
              : 'transfer';
    }
    final projection = membershipProjection(next, today);
    final site = await tx.get('class_locations/${projection['locationId']}');
    require(site != null);
    final indexes =
        await _indexes(tx, changed.map((p) => p['locationId'] as String));
    final count = await tx.get('yellow_ribbon_counts/$sid');
    require(count != null, 'failed-precondition');
    final oldEnrollments = <String, RosterMap?>{};
    for (final p in changed) {
      oldEnrollments[p['id'] as String] =
          await tx.get('student_enrollments/${p['id']}');
    }
    final historySites = <String>{
      ...List<String>.from(student['timelineSites'] ?? []),
      ...next.map((p) => p['locationId'] as String)
    }.toList();
    final revision = (student['enrollmentRevision'] as int) + 1;
    for (final p in changed) {
      final old = oldEnrollments[p['id']];
      tx.set(
          'student_enrollments/${p['id']}',
          {
            ...indexEntry(p),
            'startKnown': p['startKnown'] != false,
            'revision': (old?['revision'] as int? ?? 0) + 1,
            if (old == null) 'source': input['mode'],
            if (correction) ...{
              'correctionReason': input['reason'],
              'previousPeriod': {
                'startDate': old?['startDate'],
                'endDateExclusive': old?['endDateExclusive']
              }
            },
            ...stamp(uid, op)
          },
          merge: true);
    }
    tx.set(
        'students/$sid',
        {
          ...projection,
          'classLocation': site!['name'],
          'enrollmentRevision': revision,
          'enrollmentTimeline': next,
          'timelineSites': historySites,
          'enrollmentChange': {'kind': changeKind, 'index': index},
          ...stamp(uid, op)
        },
        merge: true);
    tx.set(
        'student_summaries/$sid',
        {
          'name': student['name'],
          'locationIds': historySites,
          'enrollmentTimeline': next,
          'archived': projection['archived']
        },
        merge: true);
    tx.set(
        'yellow_ribbon_counts/$sid',
        {
          'locationIds': historySites,
          'lastUpdated': store.serverTimestamp,
          'updatedBy': uid,
          'lastOperationId': op
        },
        merge: true);
    _writeIndexes(tx, indexes, changed);
    return {
      'studentId': sid,
      'revision': revision,
      'locationIds': touched.toList()
    };
  }

  Future<RosterMap> _redeem(RosterCommandTransaction tx, RosterMap access,
      String uid, RosterMap input) async {
    final sid = id(input['studentId']),
        op = id(input['operationId']),
        amount = input['amount'];
    require(amount is int && amount > 0 && amount <= 10000);
    final student = await tx.get('students/$sid'),
        count = await tx.get('yellow_ribbon_counts/$sid');
    require(student != null, 'not-found');
    require(student!['enrollmentTimeline'] is List, 'failed-precondition');
    final periods = (student['enrollmentTimeline'] as List).map(map).toList();
    require(periods.isNotEmpty, 'failed-precondition');
    final projection = membershipProjection(periods, today);
    final loc = projection['locationId'] as String;
    final selected = periods.firstWhere((p) =>
        p['locationId'] == loc &&
        p['startDate'] == projection['enrollmentStartDate']);
    scope(access, loc);
    require(count != null, 'failed-precondition');
    final total = count!['totalCount'] as num? ?? 0,
        used = count['usedCount'] as num? ?? 0;
    require(total - used >= (amount as int));
    tx.set(
        'yellow_ribbon_counts/$sid',
        {
          'totalCount': total,
          'usedCount': used + amount,
          'locationId': loc,
          'dateKey': today,
          'enrollmentId': selected['id'],
          'lastUpdated': store.serverTimestamp,
          'updatedBy': uid,
          'lastOperationId': op
        },
        merge: true);
    tx.set('ribbon_events/$op.$sid', {
      'studentId': sid,
      'locationId': loc,
      'kind': 'redemption',
      'dateKey': today,
      'amount': amount,
      'operationId': op,
      'updatedBy': uid,
      'createdAt': store.serverTimestamp
    });
    return {
      'studentId': sid,
      'totalCount': total,
      'usedCount': used + amount,
      'locationIds': [loc]
    };
  }
}
