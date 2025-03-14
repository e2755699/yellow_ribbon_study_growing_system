import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';

class DailyPerformanceRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentsRepo _studentsRepo;

  DailyPerformanceRepo(this._studentsRepo);

  /// Helper method to generate document ID
  String _getDocumentId(DateTime date, ClassLocation classLocation) {
    return DateFormatter.formatToDocId(date, classLocation.name);
  }

  /// 加载指定日期和班级的每日表现数据
  Future<DailyPerformanceInfo> load(
      DateTime date, ClassLocation classLocation) async {
    try {
      // 使用工具类生成文档ID
      String docId = _getDocumentId(date, classLocation);

      // 尝试从 Firestore 加载数据
      final docSnapshot = await _firestore
          .collection('daily_performances')
          .doc(docId)
          .get();

      if (docSnapshot.exists) {
        // 如果文档存在，转换为 DailyPerformanceInfo 对象
        return DailyPerformanceInfo.fromFirebase(
            docSnapshot.data()!, docSnapshot.id);
      } else {
        // 如果文档不存在，创建新的 DailyPerformanceInfo 对象
        // 首先加载该班级的所有学生
        final students = await _studentsRepo.load();
        final filteredStudents = students
            .where((student) => student.classLocation == classLocation.name)
            .toList();

        // 为每个学生创建表现记录，并传递日期
        final records = filteredStudents
            .map((student) => StudentDailyPerformanceRecord.create(student, date: date))
            .toList();

        return DailyPerformanceInfo(date, classLocation, records);
      }
    } catch (e) {
      print('Error loading daily performance: $e');
      // 发生错误时返回空的 DailyPerformanceInfo 对象
      return DailyPerformanceInfo(date, classLocation, []);
    }
  }

  /// 保存每日表现数据到 Firestore
  Future<void> save(DailyPerformanceInfo info) async {
    try {
      // 使用工具类生成文档ID
      String docId = _getDocumentId(info.date, info.classLocation);

      // 将 DailyPerformanceInfo 对象转换为 Firestore 数据并保存
      await _firestore
          .collection('daily_performances')
          .doc(docId)
          .set(info.toFirebase());
    } catch (e) {
      print('Error saving daily performance: $e');
    }
  }

  /// 删除每日表现数据
  Future<void> delete(DateTime date, ClassLocation classLocation) async {
    try {
      // 使用工具类生成文档ID
      String docId = _getDocumentId(date, classLocation);

      // 删除文档
      await _firestore.collection('daily_performances').doc(docId).delete();
    } catch (e) {
      print('Error deleting daily performance: $e');
    }
  }
  
  /// 根据学生ID加载所有表现记录
  Future<List<StudentDailyPerformanceRecord>> loadByStudentId(String studentId) async {
    try {
      // 获取所有日期的表现记录
      final querySnapshot = await _firestore
          .collection('daily_performances')
          .get();
      
      List<StudentDailyPerformanceRecord> allRecords = [];
      
      // 遍历所有文档
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final records = data['records'] as List<dynamic>;
        
        // 从文档ID中提取日期
        final recordDate = DateFormatter.extractDateFromDocId(doc.id);
        if (recordDate == null) continue;
        
        // 从文档ID中提取班级位置
        final parts = doc.id.split('_');
        final classLocationStr = parts.length > 1 ? parts[1] : '';
        final classLocation = ClassLocation.fromString(classLocationStr);
        
        // 查找该学生的记录
        for (var record in records) {
          if (record['sid'] == studentId) {
            // 创建学生表现记录，并传递日期
            allRecords.add(StudentDailyPerformanceRecord.fromFirebase(
              record, 
              classLocation,
              date: recordDate,
            ));
          }
        }
      }
      
      return allRecords;
    } catch (e) {
      print('Error loading student performance: $e');
      return [];
    }
  }
  
  /// 保存单个学生的表现记录
  Future<void> saveRecord(StudentDailyPerformanceRecord record) async {
    try {
      // 使用工具类生成文档ID
      String docId = _getDocumentId(record.recordDate, record.classLocation);
      
      // 获取当前文档
      final docSnapshot = await _firestore
          .collection('daily_performances')
          .doc(docId)
          .get();
      
      if (docSnapshot.exists) {
        // 如果文档存在，更新学生记录
        final data = docSnapshot.data()!;
        final records = data['records'] as List<dynamic>;
        
        // 查找并更新该学生的记录
        bool found = false;
        for (int i = 0; i < records.length; i++) {
          if (records[i]['sid'] == record.sid) {
            records[i] = record.toFirebase();
            found = true;
            break;
          }
        }
        
        // 如果没有找到该学生的记录，添加新记录
        if (!found) {
          records.add(record.toFirebase());
        }
        
        // 更新文档
        await _firestore
            .collection('daily_performances')
            .doc(docId)
            .update({'records': records});
      } else {
        // 如果文档不存在，创建新文档
        final info = DailyPerformanceInfo(record.recordDate, record.classLocation, [record]);
        await _firestore
            .collection('daily_performances')
            .doc(docId)
            .set(info.toFirebase());
      }
    } catch (e) {
      print('Error saving student performance record: $e');
    }
  }
} 