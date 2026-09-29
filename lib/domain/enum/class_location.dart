/// A class location. The list lives in Firestore `class_locations`; students
/// and daily record document IDs reference a location by [name].
class ClassLocation {
  const ClassLocation(this.name);

  final String name;

  factory ClassLocation.fromString(String location) => ClassLocation(location);

  /// Initial locations seeded into `class_locations`; also used by in-memory
  /// fakes (tests, Widgetbook, fake data). The app reads the live list instead.
  static const seeds = [ClassLocation('台南永康區'), ClassLocation('台南北區')];

  @override
  bool operator ==(Object other) =>
      other is ClassLocation && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
