enum ClassLocation {
  tainanYongkang(1, "台南永康區"),
  tainanNaiman(2, "台南內門"),
  tainanNorthDistrict(3, "台南北區");

  final int id;
  final String name;

  const ClassLocation(this.id, this.name);

  factory ClassLocation.fromString(String location){
    //todo error handle
    return ClassLocation.values
        .where((classLocation) => classLocation.name == location).first;
  }
}
