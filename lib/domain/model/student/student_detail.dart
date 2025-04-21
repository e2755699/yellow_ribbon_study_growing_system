import 'dart:math';

class StudentDetail {
  String? id;
  String name;
  String classLocation;
  String gender;
  String phone;
  DateTime birthday;
  String idNumber;
  String school;
  String email;
  EconomicStatus economicStatus;

  // 法定代理人或監護人資料
  String guardianName;
  String guardianIdNumber;
  String guardianCompany;
  String guardianPhone;
  String guardianEmail;

  // 緊急聯絡人
  String emergencyContactName;
  String emergencyContactIdNumber;
  String emergencyContactCompany;
  String emergencyContactPhone;
  String emergencyContactEmail;
  String description;

  // 其他
  bool hasSpecialDisease;
  String? specialDiseaseDescription;
  bool isSpecialStudent;
  String? specialStudentDescription;
  bool needsPickup;
  String? pickupRequirementDescription;
  FamilyStatus familyStatus;
  EthnicStatus ethnicStatus;
  String interest;
  String abilityEvaluation;
  String learningGoals;
  String resourcesAndScholarships;
  String talentClass;
  String specialCourse;
  String studentIntroduction;
  String? avatar;

  StudentDetail(
    this.id, {
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

  static StudentDetail empty() {
    return StudentDetail(
      null,
      name: "",
      classLocation: "台南永康區",
      gender: "男",
      phone: "",
      birthday: DateTime(DateTime.now().year - 15, 01, 01),
      // 默認一個過去的日期
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
      familyStatus: FamilyStatus.values.first,
      ethnicStatus: EthnicStatus.none,
      // 默認取第一個值
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'classLocation': classLocation,
      'gender': gender,
      'phone': phone,
      'birthday': birthday,
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
