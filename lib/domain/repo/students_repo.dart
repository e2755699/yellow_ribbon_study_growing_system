import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

class StudentsRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StudentDetail>? _students;

  StudentDetail getStudentDetail(String sid) {
    return _students
        ?.where((student) => student.id == sid)
        .firstOrNull ??
        StudentDetail.empty();
    ;
  }

  /// Load all students from Firestore
  Future<List<StudentDetail>> load() async {
    try {
      final snapshot = await _firestore.collection('students').get();
      var students = snapshot.docs.map((doc) {
        final data = doc.data();
        return StudentDetail(
          doc.id,
          // 使用文檔 ID 作為學生 ID
          name: data['name'] ?? '',
          classLocation: data['name'] ?? '',
          gender: data['gender'] ?? '',
          phone: data['phone'] ?? '',
          birthday:
          (data['birthday'] as Timestamp?)?.toDate() ?? DateTime.now(),
          idNumber: data['idNumber'] ?? '',
          school: data['school'] ?? '',
          email: data['email'] ?? '',
          fatherName: data['fatherName'] ?? '',
          fatherIdNumber: data['fatherIdNumber'] ?? '',
          fatherCompany: data['fatherCompany'] ?? '',
          fatherPhone: data['fatherPhone'] ?? '',
          fatherEmail: data['fatherEmail'] ?? '',
          motherName: data['motherName'] ?? '',
          motherIdNumber: data['motherIdNumber'] ?? '',
          motherCompany: data['motherCompany'] ?? '',
          motherPhone: data['motherPhone'] ?? '',
          motherEmail: data['motherEmail'] ?? '',
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
          interest: data['interest'] ?? '',
          personality: data['personality'] ?? '',
          mentalStatus: data['mentalStatus'] ?? '',
          socialSkills: data['socialSkills'] ?? '',
          abilityEvaluation: data['abilityEvaluation'] ?? '',
          learningGoals: data['learningGoals'] ?? '',
          resourcesAndScholarships: data['resourcesAndScholarships'] ?? '',
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
  Future<void> create(StudentDetail student) async {
    try {
      await _firestore.collection('students').add({
        'name': student.name,
        'classLocation' : student.classLocation,
        'gender': student.gender,
        'phone': student.phone,
        'birthday': student.birthday,
        'idNumber': student.idNumber,
        'school': student.school,
        'email': student.email,
        'fatherName': student.fatherName,
        'fatherIdNumber': student.fatherIdNumber,
        'fatherCompany': student.fatherCompany,
        'fatherPhone': student.fatherPhone,
        'fatherEmail': student.fatherEmail,
        'motherName': student.motherName,
        'motherIdNumber': student.motherIdNumber,
        'motherCompany': student.motherCompany,
        'motherPhone': student.motherPhone,
        'motherEmail': student.motherEmail,
        'emergencyContactName': student.emergencyContactName,
        'emergencyContactIdNumber': student.emergencyContactIdNumber,
        'emergencyContactCompany': student.emergencyContactCompany,
        'emergencyContactPhone': student.emergencyContactPhone,
        'emergencyContactEmail': student.emergencyContactEmail,
        'hasSpecialDisease': student.hasSpecialDisease,
        'specialDiseaseDescription': student.specialDiseaseDescription,
        'isSpecialStudent': student.isSpecialStudent,
        'specialStudentDescription': student.specialStudentDescription,
        'needsPickup': student.needsPickup,
        'pickupRequirementDescription': student.pickupRequirementDescription,
        'familyStatus': student.familyStatus.index,
        'interest': student.interest,
        'personality': student.personality,
        'mentalStatus': student.mentalStatus,
        'socialSkills': student.socialSkills,
        'abilityEvaluation': student.abilityEvaluation,
        'learningGoals': student.learningGoals,
        'resourcesAndScholarships': student.resourcesAndScholarships,
      });
    } catch (e) {
      print('Error creating student: $e');
    }
  }

  /// Update an existing student in Firestore
  Future<void> update(String id, StudentDetail student) async {
    try {
      await _firestore.collection('students').doc(id).update({
        'name': student.name,
        'classLocation' : student.classLocation,
        'gender': student.gender,
        'phone': student.phone,
        'birthday': student.birthday,
        'idNumber': student.idNumber,
        'school': student.school,
        'email': student.email,
        'fatherName': student.fatherName,
        'fatherIdNumber': student.fatherIdNumber,
        'fatherCompany': student.fatherCompany,
        'fatherPhone': student.fatherPhone,
        'fatherEmail': student.fatherEmail,
        'motherName': student.motherName,
        'motherIdNumber': student.motherIdNumber,
        'motherCompany': student.motherCompany,
        'motherPhone': student.motherPhone,
        'motherEmail': student.motherEmail,
        'emergencyContactName': student.emergencyContactName,
        'emergencyContactIdNumber': student.emergencyContactIdNumber,
        'emergencyContactCompany': student.emergencyContactCompany,
        'emergencyContactPhone': student.emergencyContactPhone,
        'emergencyContactEmail': student.emergencyContactEmail,
        'hasSpecialDisease': student.hasSpecialDisease,
        'specialDiseaseDescription': student.specialDiseaseDescription,
        'isSpecialStudent': student.isSpecialStudent,
        'specialStudentDescription': student.specialStudentDescription,
        'needsPickup': student.needsPickup,
        'pickupRequirementDescription': student.pickupRequirementDescription,
        'familyStatus': student.familyStatus.index,
        'interest': student.interest,
        'personality': student.personality,
        'mentalStatus': student.mentalStatus,
        'socialSkills': student.socialSkills,
        'abilityEvaluation': student.abilityEvaluation,
        'learningGoals': student.learningGoals,
        'resourcesAndScholarships': student.resourcesAndScholarships,
      });
    } catch (e) {
      print('Error updating student: $e');
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
