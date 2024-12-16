
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';

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

  // 父母資料
  String fatherName;
  String fatherIdNumber;
  String fatherCompany;
  String fatherPhone;
  String fatherEmail;
  String motherName;
  String motherIdNumber;
  String motherCompany;
  String motherPhone;
  String motherEmail;

  // 緊急聯絡人
  String emergencyContactName;
  String emergencyContactIdNumber;
  String emergencyContactCompany;
  String emergencyContactPhone;
  String emergencyContactEmail;

  // 其他
  bool hasSpecialDisease;
  String? specialDiseaseDescription;
  bool isSpecialStudent;
  String? specialStudentDescription;
  bool needsPickup;
  String? pickupRequirementDescription;
  FamilyStatus familyStatus;
  String interest;
  String personality;
  String mentalStatus;
  String socialSkills;
  String abilityEvaluation;
  String learningGoals;
  String resourcesAndScholarships;

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
    required this.fatherName,
    required this.fatherIdNumber,
    required this.fatherCompany,
    required this.fatherPhone,
    required this.fatherEmail,
    required this.motherName,
    required this.motherIdNumber,
    required this.motherCompany,
    required this.motherPhone,
    required this.motherEmail,
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
    required this.interest,
    required this.personality,
    required this.mentalStatus,
    required this.socialSkills,
    required this.abilityEvaluation,
    required this.learningGoals,
    required this.resourcesAndScholarships,
  });

  static StudentDetail empty() {
    return StudentDetail(
      null,
      name: "",
      classLocation : "台南永康區",
      gender: "男",
      phone: "",
      birthday: DateTime(DateTime.now().year - 15, 01, 01),
      // 默認一個過去的日期
      idNumber: "",
      school: "",
      email: "",
      fatherName: "",
      fatherIdNumber: "",
      fatherCompany: "",
      fatherPhone: "",
      fatherEmail: "",
      motherName: "",
      motherIdNumber: "",
      motherCompany: "",
      motherPhone: "",
      motherEmail: "",
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
      // 默認取第一個值
      interest: "選項1",
      personality: "選項1",
      mentalStatus: "選項1",
      socialSkills: "選項1",
      abilityEvaluation: "選項1",
      learningGoals: "選項1",
      resourcesAndScholarships: "選項1",
    );
  }
}

enum FamilyStatus {
  bothParents, // 雙親
  singleParentWithFather, // 單親與父同住
  singleParentWithMother, // 單親與母同住
  grandparentCare, // 隔代教養
}
