import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

class StudentsRepo {
  StudentDetail getStudentDetail(int? sid) {
    return load().where((student) => student.id == sid).firstOrNull ??
        StudentDetail.empty();
    ;
  }

  List<StudentDetail> load() {
    return List.generate(10, (index) {
      return StudentDetail(
        id: index + 1,
        name: "學生$index",
        gender: index % 2 == 0 ? "男" : "女",
        phone: "0900-123-45$index",
        birthday: DateTime(2000 + index, index % 12 + 1, (index % 28) + 1),
        idNumber: "A1234567${index}X",
        school: "學校$index",
        email: "student$index@example.com",
        fatherName: "父親$index",
        fatherIdNumber: "F1234567${index}X",
        fatherCompany: "公司$index",
        fatherPhone: "0910-987-65$index",
        fatherEmail: "father$index@example.com",
        motherName: "母親$index",
        motherIdNumber: "M1234567${index}X",
        motherCompany: "公司$index",
        motherPhone: "0920-876-54$index",
        motherEmail: "mother$index@example.com",
        emergencyContactName: "聯絡人$index",
        emergencyContactIdNumber: "E1234567${index}X",
        emergencyContactCompany: "公司$index",
        emergencyContactPhone: "0930-765-43$index",
        emergencyContactEmail: "contact$index@example.com",
        hasSpecialDisease: index % 3 == 0,
        specialDiseaseDescription: index % 3 == 0 ? "特殊疾病描述$index" : null,
        isSpecialStudent: index % 4 == 0,
        specialStudentDescription: index % 4 == 0 ? "特殊學生描述$index" : null,
        needsPickup: index % 5 == 0,
        pickupRequirementDescription: index % 5 == 0 ? "接送需求描述$index" : null,
        familyStatus: FamilyStatus.values[index % 4],
        interest: "興趣$index",
        personality: "個性$index",
        mentalStatus: "身心狀態$index",
        socialSkills: "社交技巧$index",
        abilityEvaluation: "能力評估$index",
        learningGoals: "學習目標$index",
        resourcesAndScholarships: "物資及獎助學金$index",
      );
    });
  }
}
