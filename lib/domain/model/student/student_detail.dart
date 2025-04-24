import 'dart:math';

class StudentDetail {
  final String? id;
  final String name;
  final String classLocation;
  final String gender;
  final String phone;
  final DateTime birthday;
  final String idNumber;
  final String school;
  final String email;
  final EconomicStatus economicStatus;

  // 法定代理人或監護人資料
  final String guardianName;
  final String guardianIdNumber;
  final String guardianCompany;
  final String guardianPhone;
  final String guardianEmail;

  // 緊急聯絡人
  final String emergencyContactName;
  final String emergencyContactIdNumber;
  final String emergencyContactCompany;
  final String emergencyContactPhone;
  final String emergencyContactEmail;
  final String description;

  // 其他
  final bool hasSpecialDisease;
  final String? specialDiseaseDescription;
  final bool isSpecialStudent;
  final String? specialStudentDescription;
  final bool needsPickup;
  final String? pickupRequirementDescription;
  final FamilyStatus familyStatus;
  final EthnicStatus ethnicStatus;
  final String interest;
  final String abilityEvaluation;
  final String learningGoals;
  final String resourcesAndScholarships;
  final String talentClass;
  final String specialCourse;
  final String studentIntroduction;
  final String? avatar;

  StudentDetail({
    this.id,
    required this.name,
    required this.classLocation,
    required this.gender,
    required this.phone,
    required this.birthday,
    required this.idNumber,
    required this.school,
    required this.email,
    required this.economicStatus,
    required this.guardianName,
    required this.guardianIdNumber,
    required this.guardianCompany,
    required this.guardianPhone,
    required this.guardianEmail,
    required this.emergencyContactName,
    required this.emergencyContactIdNumber,
    required this.emergencyContactCompany,
    required this.emergencyContactPhone,
    required this.emergencyContactEmail,
    required this.hasSpecialDisease,
    this.specialDiseaseDescription,
    required this.isSpecialStudent,
    this.specialStudentDescription,
    required this.needsPickup,
    this.pickupRequirementDescription,
    required this.familyStatus,
    required this.ethnicStatus,
    required this.interest,
    required this.abilityEvaluation,
    required this.learningGoals,
    required this.resourcesAndScholarships,
    required this.talentClass,
    required this.specialCourse,
    required this.studentIntroduction,
    this.avatar,
    required this.description,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    return StudentDetail(
      id: json['id'],
      name: json['name'],
      classLocation: json['classLocation'],
      gender: json['gender'],
      phone: json['phone'],
      birthday: DateTime.parse(json['birthday']),
      idNumber: json['idNumber'],
      school: json['school'],
      email: json['email'],
      economicStatus: EconomicStatus.values[json['economicStatus']],
      guardianName: json['guardianName'],
      guardianIdNumber: json['guardianIdNumber'],
      guardianCompany: json['guardianCompany'],
      guardianPhone: json['guardianPhone'],
      guardianEmail: json['guardianEmail'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactIdNumber: json['emergencyContactIdNumber'],
      emergencyContactCompany: json['emergencyContactCompany'],
      emergencyContactPhone: json['emergencyContactPhone'],
      emergencyContactEmail: json['emergencyContactEmail'],
      hasSpecialDisease: json['hasSpecialDisease'],
      specialDiseaseDescription: json['specialDiseaseDescription'],
      isSpecialStudent: json['isSpecialStudent'],
      specialStudentDescription: json['specialStudentDescription'],
      needsPickup: json['needsPickup'],
      pickupRequirementDescription: json['pickupRequirementDescription'],
      familyStatus: FamilyStatus.values[json['familyStatus']],
      ethnicStatus: EthnicStatus.values[json['ethnicStatus']],
      interest: json['interest'],
      abilityEvaluation: json['abilityEvaluation'],
      learningGoals: json['learningGoals'],
      resourcesAndScholarships: json['resourcesAndScholarships'],
      talentClass: json['talentClass'],
      specialCourse: json['specialCourse'],
      studentIntroduction: json['studentIntroduction'],
      avatar: json['avatar'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classLocation': classLocation,
      'gender': gender,
      'phone': phone,
      'birthday': birthday.toIso8601String(),
      'idNumber': idNumber,
      'school': school,
      'email': email,
      'economicStatus': economicStatus.index,
      'guardianName': guardianName,
      'guardianIdNumber': guardianIdNumber,
      'guardianCompany': guardianCompany,
      'guardianPhone': guardianPhone,
      'guardianEmail': guardianEmail,
      'emergencyContactName': emergencyContactName,
      'emergencyContactIdNumber': emergencyContactIdNumber,
      'emergencyContactCompany': emergencyContactCompany,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactEmail': emergencyContactEmail,
      'hasSpecialDisease': hasSpecialDisease,
      'specialDiseaseDescription': specialDiseaseDescription,
      'isSpecialStudent': isSpecialStudent,
      'specialStudentDescription': specialStudentDescription,
      'needsPickup': needsPickup,
      'pickupRequirementDescription': pickupRequirementDescription,
      'familyStatus': familyStatus.index,
      'ethnicStatus': ethnicStatus.index,
      'interest': interest,
      'abilityEvaluation': abilityEvaluation,
      'learningGoals': learningGoals,
      'resourcesAndScholarships': resourcesAndScholarships,
      'talentClass': talentClass,
      'specialCourse': specialCourse,
      'studentIntroduction': studentIntroduction,
      'avatar': avatar,
      'description': description,
    };
  }

  static StudentDetail empty() {
    return StudentDetail(
      id: null,
      name: "",
      classLocation: "台南永康區",
      gender: "男",
      phone: "",
      birthday: DateTime(DateTime.now().year - 15, 01, 01),
      idNumber: "",
      school: "",
      email: "",
      economicStatus: EconomicStatus.normal,
      guardianName: "",
      guardianIdNumber: "",
      guardianCompany: "",
      guardianPhone: "",
      guardianEmail: "",
      emergencyContactName: "",
      emergencyContactIdNumber: "",
      emergencyContactCompany: "",
      emergencyContactPhone: "",
      emergencyContactEmail: "",
      hasSpecialDisease: false,
      specialDiseaseDescription: null,
      isSpecialStudent: false,
      specialStudentDescription: null,
      needsPickup: false,
      pickupRequirementDescription: null,
      familyStatus: FamilyStatus.bothParents,
      ethnicStatus: EthnicStatus.none,
      interest: "選項1",
      abilityEvaluation: "選項1",
      learningGoals: "選項1",
      resourcesAndScholarships: "選項1",
      talentClass: "",
      specialCourse: "",
      studentIntroduction: "",
      avatar: null,
      description: "",
    );
  }

  StudentDetail copyWith({
    String? id,
    String? name,
    String? classLocation,
    String? gender,
    String? phone,
    DateTime? birthday,
    String? idNumber,
    String? school,
    String? email,
    EconomicStatus? economicStatus,
    String? guardianName,
    String? guardianIdNumber,
    String? guardianCompany,
    String? guardianPhone,
    String? guardianEmail,
    String? emergencyContactName,
    String? emergencyContactIdNumber,
    String? emergencyContactCompany,
    String? emergencyContactPhone,
    String? emergencyContactEmail,
    bool? hasSpecialDisease,
    String? specialDiseaseDescription,
    bool? isSpecialStudent,
    String? specialStudentDescription,
    bool? needsPickup,
    String? pickupRequirementDescription,
    FamilyStatus? familyStatus,
    EthnicStatus? ethnicStatus,
    String? interest,
    String? abilityEvaluation,
    String? learningGoals,
    String? resourcesAndScholarships,
    String? talentClass,
    String? specialCourse,
    String? studentIntroduction,
    String? avatar,
    String? description,
  }) {
    return StudentDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      classLocation: classLocation ?? this.classLocation,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      idNumber: idNumber ?? this.idNumber,
      school: school ?? this.school,
      email: email ?? this.email,
      economicStatus: economicStatus ?? this.economicStatus,
      guardianName: guardianName ?? this.guardianName,
      guardianIdNumber: guardianIdNumber ?? this.guardianIdNumber,
      guardianCompany: guardianCompany ?? this.guardianCompany,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactIdNumber:
          emergencyContactIdNumber ?? this.emergencyContactIdNumber,
      emergencyContactCompany:
          emergencyContactCompany ?? this.emergencyContactCompany,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactEmail:
          emergencyContactEmail ?? this.emergencyContactEmail,
      hasSpecialDisease: hasSpecialDisease ?? this.hasSpecialDisease,
      specialDiseaseDescription:
          specialDiseaseDescription ?? this.specialDiseaseDescription,
      isSpecialStudent: isSpecialStudent ?? this.isSpecialStudent,
      specialStudentDescription:
          specialStudentDescription ?? this.specialStudentDescription,
      needsPickup: needsPickup ?? this.needsPickup,
      pickupRequirementDescription:
          pickupRequirementDescription ?? this.pickupRequirementDescription,
      familyStatus: familyStatus ?? this.familyStatus,
      ethnicStatus: ethnicStatus ?? this.ethnicStatus,
      interest: interest ?? this.interest,
      abilityEvaluation: abilityEvaluation ?? this.abilityEvaluation,
      learningGoals: learningGoals ?? this.learningGoals,
      resourcesAndScholarships:
          resourcesAndScholarships ?? this.resourcesAndScholarships,
      talentClass: talentClass ?? this.talentClass,
      specialCourse: specialCourse ?? this.specialCourse,
      studentIntroduction: studentIntroduction ?? this.studentIntroduction,
      avatar: avatar ?? this.avatar,
      description: description ?? this.description,
    );
  }
}

enum FamilyStatus {
  bothParents, // 雙親
  singleParentWithFather, // 單親與父同住
  singleParentWithMother, // 單親與母同住
  grandparentCare, // 隔代教養
}

enum EthnicStatus {
  none, // 非原住民/新住民
  indigenous, // 原住民
  newResident, // 新住民
}

enum EconomicStatus {
  normal, // 一般
  mediumLowIncome, // 中低收入戶
  lowIncome, // 低收入戶
}
