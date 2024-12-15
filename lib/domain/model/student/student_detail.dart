class StudentDetail {
  int id;
  String name;
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
  String parentStatus;
  String familyStatus;
  String interest;
  String personality;
  String mentalStatus;
  String socialSkills;
  String abilityEvaluation;
  String learningGoals;
  String resourcesAndScholarships;

  StudentDetail({
    required this.id,
    required this.name,
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
    required this.parentStatus,
    required this.familyStatus,
    required this.interest,
    required this.personality,
    required this.mentalStatus,
    required this.socialSkills,
    required this.abilityEvaluation,
    required this.learningGoals,
    required this.resourcesAndScholarships,
  });

  static empty() {}
}
