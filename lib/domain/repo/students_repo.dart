import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

class StudentsRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StudentDetail>? _students;

  StudentDetail getStudentDetail(String sid) {
    return _students?.where((student) => student.id == sid).firstOrNull ??
        StudentDetail.empty();
  }

  /// Load all students from Firestore
  Future<List<StudentDetail>> load() async {
    try {
      final snapshot = await _firestore.collection('students').get();
      var students = snapshot.docs.map((doc) {
        final data = doc.data();
        return StudentDetail(
          id: doc.id,
          name: data['name'] ?? '',
          classLocation: data['classLocation'] ?? '',
          gender: data['gender'] ?? '',
          phone: data['phone'] ?? '',
          birthday:
              (data['birthday'] as Timestamp?)?.toDate() ?? DateTime.now(),
          idNumber: data['idNumber'] ?? '',
          school: data['school'] ?? '',
          email: data['email'] ?? '',
          economicStatus: EconomicStatus.values[(data['economicStatus'] ?? 0)
              .clamp(0, EconomicStatus.values.length - 1)],
          guardianName: data['guardianName'] ?? '',
          guardianIdNumber: data['guardianIdNumber'] ?? '',
          guardianCompany: data['guardianCompany'] ?? '',
          guardianPhone: data['guardianPhone'] ?? '',
          guardianEmail: data['guardianEmail'] ?? '',
          emergencyContactName: data['emergencyContactName'] ?? '',
          emergencyContactIdNumber: data['emergencyContactIdNumber'] ?? '',
          emergencyContactCompany: data['emergencyContactCompany'] ?? '',
          emergencyContactPhone: data['emergencyContactPhone'] ?? '',
          emergencyContactEmail: data['emergencyContactEmail'] ?? '',
          hasSpecialDisease: data['hasSpecialDisease'] ?? false,
          specialDiseaseDescription: data['specialDiseaseDescription'],
          isSpecialStudent: data['isSpecialStudent'] ?? false,
          specialStudentDescription: data['specialStudentDescription'],
          needsPickup: data['needsPickup'] ?? false,
          pickupRequirementDescription: data['pickupRequirementDescription'],
          familyStatus: FamilyStatus.values[(data['familyStatus'] ?? 0)
              .clamp(0, FamilyStatus.values.length - 1)],
          ethnicStatus: EthnicStatus.values[(data['ethnicStatus'] ?? 0)
              .clamp(0, EthnicStatus.values.length - 1)],
          interest: data['interest'] ?? '',
          abilityEvaluation: data['abilityEvaluation'] ?? '',
          learningGoals: data['learningGoals'] ?? '',
          resourcesAndScholarships: data['resourcesAndScholarships'] ?? '',
          talentClass: data['talentClass'] ?? '',
          specialCourse: data['specialCourse'] ?? '',
          studentIntroduction: data['studentIntroduction'] ?? '',
          avatar: data['avatar'],
          description: data['description'] ?? '',
        );
      }).toList();
      _students = students;
      return students;
    } catch (e) {
      print('Error loading students: $e');
      return [];
    }
  }

  /// Create a new student in Firestore
  Future<String?> create(StudentDetail student) async {
    try {
      final docRef =
          await _firestore.collection('students').add(student.toJson());
      return docRef.id;
    } catch (e) {
      print('Error creating student: $e');
      return null;
    }
  }

  /// Update an existing student in Firestore
  Future<void> update(String id, StudentDetail student) async {
    try {
      await _firestore.collection('students').doc(id).update(student.toJson());
    } catch (e) {
      print('Error updating student: $e');
    }
  }

  Future<void> addFakeData() async {
    try {
      await create(StudentDetail(
          name: "劉兆凌",
          classLocation: ClassLocation.tainanNorthDistrict.name,
          gender: "男",
          phone: "0928778673",
          birthday: DateTime(1987, 09, 03),
          idNumber: "D12312763",
          school: "勝利國小",
          email: "e2755699@gmail.com",
          economicStatus: EconomicStatus.normal,
          guardianName: "劉鳳台",
          guardianIdNumber: "E121827331",
          guardianCompany: "兆慶牙科",
          guardianPhone: "(06)2234644",
          guardianEmail: "e2755699@gmail.com",
          emergencyContactName: "林怡玲",
          emergencyContactIdNumber: "0928778673",
          emergencyContactCompany: "百世家",
          emergencyContactPhone: "",
          emergencyContactEmail: "sally010@gmail.com",
          hasSpecialDisease: false,
          isSpecialStudent: false,
          needsPickup: true,
          familyStatus: FamilyStatus.singleParentWithFather,
          ethnicStatus: EthnicStatus.none,
          interest: "選項1",
          abilityEvaluation: "選項1",
          learningGoals: "選項1",
          resourcesAndScholarships: "選項1",
          talentClass: "木箱鼓",
          specialCourse: "自然科學",
          studentIntroduction:
              "劉兆凌是一位活潑開朗的學生，喜歡運動和音樂。他在學校表現優異，特別在數學和科學方面有天賦。課餘時間喜歡彈奏木箱鼓，並經常參加學校的音樂表演。他與同學相處融洽，樂於助人，是老師眼中的好學生。雖然家庭環境較為特殊，但他積極樂觀，努力學習，希望將來能成為一名醫生，幫助更多有需要的人。",
          avatar: null,
          description: "活潑好動"));
      print("add fake data");
    } catch (e, st) {
      print("add fake data error $e $st");
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection('students').doc(id).delete();
    } catch (e) {
      print("刪除失敗：$e");
    }
  }
}
