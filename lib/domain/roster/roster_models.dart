/// A calendar date in Taiwan, stored lexically for stable range queries.
class BusinessDate implements Comparable<BusinessDate> {
  final String value;
  BusinessDate(this.value) {
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsed == null ||
        _format(parsed) != value) {
      throw FormatException('Invalid business date', value);
    }
  }
  factory BusinessDate.today([DateTime? instant]) => BusinessDate(_format(
      (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 8))));
  factory BusinessDate.fromCalendar(DateTime date) =>
      BusinessDate(_format(date));
  static String _format(DateTime d) => [
        d.year.toString().padLeft(4, '0'),
        d.month.toString().padLeft(2, '0'),
        d.day.toString().padLeft(2, '0')
      ].join('-');
  DateTime get calendar => DateTime.parse(value);
  @override
  int compareTo(BusinessDate other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) =>
      other is BusinessDate && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

class ClassSite {
  final String id, name;
  final int order;
  final bool active;
  const ClassSite(this.id, this.name, {this.order = 0, this.active = true});
}

class StudentSummary {
  final String id, name;
  final bool archived;
  const StudentSummary(this.id, this.name, {this.archived = false});
}

class Enrollment {
  final String id, studentId, locationId;
  final BusinessDate startDate, endDateExclusive;
  final bool startKnown;
  final int revision;
  const Enrollment(this.id,
      {required this.studentId,
      required this.locationId,
      required this.startDate,
      required this.endDateExclusive,
      this.startKnown = true,
      this.revision = 1});
  bool includes(BusinessDate date) =>
      startDate.compareTo(date) <= 0 && endDateExclusive.compareTo(date) > 0;
  factory Enrollment.fromJson(String id, Map<String, dynamic> data) =>
      Enrollment(id,
          studentId: data['studentId'] as String,
          locationId: data['locationId'] as String,
          startDate: BusinessDate(data['startDate'] as String),
          endDateExclusive: BusinessDate(data['endDateExclusive'] as String),
          startKnown: data['startKnown'] as bool? ?? true,
          revision: data['revision'] as int? ?? 1);
  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'locationId': locationId,
        'startDate': startDate.value,
        'endDateExclusive': endDateExclusive.value,
        'startKnown': startKnown,
        'revision': revision,
      };
}

enum SessionStatus { held, cancelled, legacyUnverified }

class ClassSession {
  final String locationId;
  final BusinessDate date;
  final SessionStatus status;
  final int revision;
  const ClassSession(this.locationId, this.date, this.status,
      {this.revision = 0});
  String get id => [date.value, locationId].join('.');
}

dynamic freezeRecordValue(dynamic value) {
  if (value is List) return List.unmodifiable(value.map(freezeRecordValue));
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(value.map(
        (key, value) => MapEntry(key as String, freezeRecordValue(value))));
  }
  return value;
}

class DailyRecord {
  final String kind, studentId, locationId, provenance;
  final String nameSnapshot;
  final String? enrollmentId;
  final BusinessDate date;
  final int revision;
  final Map<String, dynamic> values;
  final List<String> confirmedFields;
  DailyRecord(this.kind,
      {required this.studentId,
      required this.locationId,
      required this.date,
      required Map<String, dynamic> values,
      this.enrollmentId,
      this.revision = 0,
      this.provenance = 'confirmed',
      this.nameSnapshot = '',
      List<String> confirmedFields = const []})
      : values = freezeRecordValue(values) as Map<String, dynamic>,
        confirmedFields = List.unmodifiable(confirmedFields);
  bool fieldConfirmed(String field) =>
      provenance == 'confirmed' || confirmedFields.contains(field);
  String get id => [date.value, locationId, studentId].join('.');
  factory DailyRecord.fromJson(String kind, Map<String, dynamic> data) =>
      DailyRecord(kind,
          studentId: data['studentId'] as String,
          locationId: data['locationId'] as String,
          date: BusinessDate(data['dateKey'] as String),
          enrollmentId: data['enrollmentId'] as String?,
          revision: data['revision'] as int? ?? 0,
          provenance: data['provenance'] as String? ?? 'legacyUnverified',
          nameSnapshot: data['nameSnapshot'] as String? ?? '',
          confirmedFields:
              List<String>.from(data['confirmedFields'] as List? ?? []),
          values: Map<String, dynamic>.from(data['values'] as Map? ?? {}));
  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'locationId': locationId,
        'dateKey': date.value,
        'enrollmentId': enrollmentId,
        'revision': revision,
        'provenance': provenance,
        'values': values,
        'nameSnapshot': nameSnapshot,
        'confirmedFields': confirmedFields,
      };
}

class RosterMember {
  final StudentSummary student;
  final Enrollment enrollment;
  const RosterMember(this.student, this.enrollment);
}

class DataSnapshot<T> {
  final T data;
  final bool fromCache;
  const DataSnapshot(this.data, {this.fromCache = false});
}

class DailyRoster {
  final BusinessDate date;
  final String locationId;
  final List<RosterMember> members;
  final Map<String, DailyRecord> attendance, performance;
  final bool fromCache;
  final ClassSession? session;
  DailyRoster(
      {required this.date,
      required this.locationId,
      required List<RosterMember> members,
      required Map<String, DailyRecord> attendance,
      required Map<String, DailyRecord> performance,
      this.session,
      this.fromCache = false})
      : members = List.unmodifiable(members),
        attendance = Map.unmodifiable(attendance),
        performance = Map.unmodifiable(performance);
  Set<String> get orphanStudentIds => {
        ...attendance.keys,
        ...performance.keys,
      }.difference(members.map((member) => member.student.id).toSet());
}
