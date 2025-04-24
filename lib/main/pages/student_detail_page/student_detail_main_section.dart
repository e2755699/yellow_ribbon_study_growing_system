import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/yellow_ribbon_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/info_card_layout.dart';

class StudentDetailMainSection extends StatefulWidget {
  late StudentDetail studentDetail;

  StudentDetailMainSection({super.key, required this.studentDetail});

  @override
  State<StudentDetailMainSection> createState() =>
      _StudentDetailMainSectionState();
}

class _StudentDetailMainSectionState extends State<StudentDetailMainSection>
    with YbToolbox {
  //student info
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _gender;
  String? _classLocation;
  String? _phone;
  DateTime? _birthday;
  String? _idNumber;
  String? _school;
  String? _email;
  String? _guardianName;
  String? _guardianIdNumber;
  String? _guardianCompany;
  String? _guardianPhone;
  String? _guardianEmail;
  String? _emergencyContactName;
  String? _description;
  String? _emergencyContactIdNumber;
  String? _emergencyContactCompany;
  String? _emergencyContactPhone;
  String? _emergencyContactEmail;
  bool _hasSpecialDisease = false;
  bool _isSpecialStudent = false;
  bool _needsPickup = false;
  String? _specialDiseaseDescription;
  String? _specialStudentDescription;
  String? _pickupRequirementDescription;

  late FamilyStatus _familyStatus;
  late EthnicStatus _ethnicStatus;
  late EconomicStatus _economicStatus;
  String? _interest;
  String? _abilityEvaluation;
  String? _learningGoals;
  String? _resourcesAndScholarships;
  String? _talentClass;
  String? _specialCourse;
  String? _studentIntroduction;
  String? _avatar;
  final StorageService _storageService = StorageService();
  bool _isUploadingAvatar = false;
  XFile? _pendingImageFile;
  int _yellowRibbonCount = 0;
  bool _isTemporary = false;

  @override
  void initState() {
    super.initState();
    _name = widget.studentDetail.name;
    _gender = widget.studentDetail.gender;
    _classLocation = widget.studentDetail.classLocation;
    _phone = widget.studentDetail.phone;
    _birthday = widget.studentDetail.birthday;
    _idNumber = widget.studentDetail.idNumber;
    _school = widget.studentDetail.school;
    _email = widget.studentDetail.email;
    _economicStatus = widget.studentDetail.economicStatus;
    _guardianName = widget.studentDetail.guardianName;
    _guardianIdNumber = widget.studentDetail.guardianIdNumber;
    _guardianCompany = widget.studentDetail.guardianCompany;
    _guardianPhone = widget.studentDetail.guardianPhone;
    _guardianEmail = widget.studentDetail.guardianEmail;
    _emergencyContactName = widget.studentDetail.emergencyContactName;
    _description = widget.studentDetail.description;
    _emergencyContactIdNumber = widget.studentDetail.emergencyContactIdNumber;
    _emergencyContactCompany = widget.studentDetail.emergencyContactCompany;
    _emergencyContactPhone = widget.studentDetail.emergencyContactPhone;
    _emergencyContactEmail = widget.studentDetail.emergencyContactEmail;
    _hasSpecialDisease = widget.studentDetail.hasSpecialDisease;
    _specialDiseaseDescription = widget.studentDetail.specialDiseaseDescription;
    _isSpecialStudent = widget.studentDetail.isSpecialStudent;
    _specialStudentDescription = widget.studentDetail.specialStudentDescription;
    _needsPickup = widget.studentDetail.needsPickup;
    _pickupRequirementDescription =
        widget.studentDetail.pickupRequirementDescription;
    _familyStatus = widget.studentDetail.familyStatus;
    _ethnicStatus = widget.studentDetail.ethnicStatus;
    _interest = widget.studentDetail.interest;
    _abilityEvaluation = widget.studentDetail.abilityEvaluation;
    _learningGoals = widget.studentDetail.learningGoals;
    _resourcesAndScholarships = widget.studentDetail.resourcesAndScholarships;
    _talentClass = widget.studentDetail.talentClass;
    _specialCourse = widget.studentDetail.specialCourse;
    _studentIntroduction = widget.studentDetail.studentIntroduction;
    _avatar = widget.studentDetail.avatar;
    _loadYellowRibbonCount();
  }

  Future<void> _loadYellowRibbonCount() async {
    if (widget.studentDetail.id != null) {
      final yellowRibbonRepo = YellowRibbonRepo();
      final ribbonCount = await yellowRibbonRepo
          .getStudentRibbonCount(widget.studentDetail.id!);

      if (mounted) {
        setState(() {
          _yellowRibbonCount = ribbonCount.unusedCount;
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Here you can replace this print statement with functionality to store data in a database or perform other actions.
      if (widget.studentDetail.id == null) {
        final newId = await GetIt.instance<StudentsRepo>().create(
          StudentDetail(
            id: null,
            name: _name!,
            classLocation: _classLocation!,
            gender: _gender!,
            phone: _phone!,
            birthday: _birthday!,
            idNumber: _idNumber!,
            school: _school!,
            email: _email!,
            economicStatus: _economicStatus,
            guardianName: _guardianName!,
            guardianIdNumber: _guardianIdNumber!,
            guardianCompany: _guardianCompany!,
            guardianPhone: _guardianPhone!,
            guardianEmail: _guardianEmail!,
            emergencyContactName: _emergencyContactName!,
            description: _description!,
            emergencyContactIdNumber: _emergencyContactIdNumber!,
            emergencyContactCompany: _emergencyContactCompany!,
            emergencyContactPhone: _emergencyContactPhone!,
            emergencyContactEmail: _emergencyContactEmail!,
            hasSpecialDisease: _hasSpecialDisease,
            specialDiseaseDescription: _specialDiseaseDescription,
            isSpecialStudent: _isSpecialStudent,
            specialStudentDescription: _specialStudentDescription,
            needsPickup: _needsPickup,
            pickupRequirementDescription: _pickupRequirementDescription,
            familyStatus: _familyStatus,
            ethnicStatus: _ethnicStatus,
            interest: _interest!,
            abilityEvaluation: _abilityEvaluation!,
            learningGoals: _learningGoals!,
            resourcesAndScholarships: _resourcesAndScholarships!,
            talentClass: _talentClass!,
            specialCourse: _specialCourse!,
            studentIntroduction: _studentIntroduction!,
            avatar: _avatar,
          ),
        );
        if (newId != null) {
          widget.studentDetail = StudentDetail(
            id: newId,
            name: _name!,
            classLocation: _classLocation!,
            gender: _gender!,
            phone: _phone!,
            birthday: _birthday!,
            idNumber: _idNumber!,
            school: _school!,
            email: _email!,
            economicStatus: _economicStatus,
            guardianName: _guardianName!,
            guardianIdNumber: _guardianIdNumber!,
            guardianCompany: _guardianCompany!,
            guardianPhone: _guardianPhone!,
            guardianEmail: _guardianEmail!,
            emergencyContactName: _emergencyContactName!,
            description: _description!,
            emergencyContactIdNumber: _emergencyContactIdNumber!,
            emergencyContactCompany: _emergencyContactCompany!,
            emergencyContactPhone: _emergencyContactPhone!,
            emergencyContactEmail: _emergencyContactEmail!,
            hasSpecialDisease: _hasSpecialDisease,
            specialDiseaseDescription: _specialDiseaseDescription,
            isSpecialStudent: _isSpecialStudent,
            specialStudentDescription: _specialStudentDescription,
            needsPickup: _needsPickup,
            pickupRequirementDescription: _pickupRequirementDescription,
            familyStatus: _familyStatus,
            ethnicStatus: _ethnicStatus,
            interest: _interest!,
            abilityEvaluation: _abilityEvaluation!,
            learningGoals: _learningGoals!,
            resourcesAndScholarships: _resourcesAndScholarships!,
            talentClass: _talentClass!,
            specialCourse: _specialCourse!,
            studentIntroduction: _studentIntroduction!,
            avatar: _avatar,
          );
          _isTemporary = false;
        }
      } else {
        await GetIt.instance<StudentsRepo>().update(
          widget.studentDetail.id!,
          StudentDetail(
            id: widget.studentDetail.id,
            name: _name!,
            classLocation: _classLocation!,
            gender: _gender!,
            phone: _phone!,
            birthday: _birthday!,
            idNumber: _idNumber!,
            school: _school!,
            email: _email!,
            economicStatus: _economicStatus,
            guardianName: _guardianName!,
            guardianIdNumber: _guardianIdNumber!,
            guardianCompany: _guardianCompany!,
            guardianPhone: _guardianPhone!,
            guardianEmail: _guardianEmail!,
            emergencyContactName: _emergencyContactName!,
            description: _description!,
            emergencyContactIdNumber: _emergencyContactIdNumber!,
            emergencyContactCompany: _emergencyContactCompany!,
            emergencyContactPhone: _emergencyContactPhone!,
            emergencyContactEmail: _emergencyContactEmail!,
            hasSpecialDisease: _hasSpecialDisease,
            specialDiseaseDescription: _specialDiseaseDescription,
            isSpecialStudent: _isSpecialStudent,
            specialStudentDescription: _specialStudentDescription,
            needsPickup: _needsPickup,
            pickupRequirementDescription: _pickupRequirementDescription,
            familyStatus: _familyStatus,
            ethnicStatus: _ethnicStatus,
            interest: _interest!,
            abilityEvaluation: _abilityEvaluation!,
            learningGoals: _learningGoals!,
            resourcesAndScholarships: _resourcesAndScholarships!,
            talentClass: _talentClass!,
            specialCourse: _specialCourse!,
            studentIntroduction: _studentIntroduction!,
            avatar: _avatar,
          ),
        );
        _isTemporary = false;
      }

      context.read<StudentDetailCubit>().save(widget.studentDetail);
    } else {
      Fluttertoast.showToast(msg: "form error , please check form!");
    }
  }

  // 處理頭像選擇
  Future<void> _handleAvatarSelected(XFile imageFile) async {
    // 先设置待上传图片，以便立即显示
    setState(() {
      _pendingImageFile = imageFile;
      _isUploadingAvatar = true;
    });

    try {
      // 显示详细日志，帮助诊断问题
      debugPrint('開始上傳頭像, 學生ID: ${widget.studentDetail.id}');
      debugPrint('文件路徑: ${imageFile.path}, 文件名: ${imageFile.name}');

      // 上傳圖片到Firebase Storage
      final fileName = await _storageService.uploadStudentAvatar(
        widget.studentDetail.id!,
        imageFile,
      );

      if (fileName != null) {
        // 如果已有頭像，先刪除舊頭像
        if (_avatar != null && _avatar!.isNotEmpty) {
          await _storageService.deleteAvatar(_avatar!);
        }

        setState(() {
          _avatar = fileName;
          context
              .read<StudentDetailCubit>()
              .updateAvatar(widget.studentDetail.id!, fileName);
          _pendingImageFile = null;
        });

        // 更新學生資料到 Firestore
        await GetIt.instance<StudentsRepo>().update(
          widget.studentDetail.id!,
          widget.studentDetail,
        );

        Fluttertoast.showToast(msg: "頭像上傳成功");
      } else {
        Fluttertoast.showToast(msg: "頭像上傳失敗，請檢查網絡連接和權限設置");
        debugPrint('頭像上傳失敗，返回的文件名為null');
      }
    } catch (e) {
      debugPrint('頭像上傳異常: $e');
      String errorMsg = "頭像上傳錯誤";

      if (e.toString().contains('unauthorized') ||
          e.toString().contains('permission-denied')) {
        errorMsg = "權限被拒絕：請檢查您的登錄狀態\n錯誤詳情: $e";
        debugPrint('Firebase權限問題，請檢查登錄狀態');
      } else if (e.toString().contains('network')) {
        errorMsg = "網絡連接問題，請檢查您的網絡連接\n錯誤詳情: $e";
      } else {
        errorMsg = "上傳失敗: $e";
      }

      // 顯示詳細錯誤對話框而不是Toast
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('頭像上傳失敗'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _infoSection(context);
  }

  Widget _infoSection(BuildContext context) {
    return Container();
  }

  InfoCardLayoutWith2Column _otherInfo(StudentDetailState state) {
    return InfoCardLayoutWith2Column(title: "其他", columns1: [
      DropdownButtonFormField(
        decoration: const InputDecoration(labelText: '興趣'),
        items: const [
          DropdownMenuItem(
            value: '選項1',
            child: Text('選項1'),
          ),
          DropdownMenuItem(
            value: '選項2',
            child: Text('選項2'),
          ),
          DropdownMenuItem(
            value: '選項3',
            child: Text('選項3'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _interest = value as String;
          });
        },
        value: _interest,
      ),
      TextFormField(
        initialValue: _talentClass,
        decoration: const InputDecoration(labelText: '才藝班'),
        onSaved: (value) => _talentClass = value,
        enabled: !state.isView,
      ),
      TextFormField(
        initialValue: _specialCourse,
        decoration: const InputDecoration(labelText: '特殊課程'),
        onSaved: (value) => _specialCourse = value,
        enabled: !state.isView,
      ),
      DropdownButtonFormField(
        decoration: const InputDecoration(labelText: '學習目標'),
        items: const [
          DropdownMenuItem(
            value: '選項1',
            child: Text('選項1'),
          ),
          DropdownMenuItem(
            value: '選項2',
            child: Text('選項2'),
          ),
          DropdownMenuItem(
            value: '選項3',
            child: Text('選項3'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _learningGoals = value as String;
          });
        },
        value: _learningGoals,
      ),
    ], columns2: [
      Row(
        children: [
          Expanded(
            child: ListTile(
              title: const Text('是否需要接送'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _needsPickup,
                    onChanged: (bool? value) {
                      setState(() {
                        _needsPickup = value ?? false;
                      });
                    },
                  ),
                  const Text('是'),
                  Checkbox(
                    value: !_needsPickup,
                    onChanged: (bool? value) {
                      setState(() {
                        _needsPickup = !(value ?? true);
                      });
                    },
                  ),
                  const Text('否'),
                ],
              ),
            ),
          ),
          if (_needsPickup)
            Expanded(
              child: TextFormField(
                initialValue: _pickupRequirementDescription,
                enabled: !state.isView,
                decoration: const InputDecoration(labelText: '接送需求描述'),
                onSaved: (value) => _pickupRequirementDescription = value,
              ),
            ),
        ],
      ),
      DropdownButtonFormField(
        decoration: const InputDecoration(labelText: '能力評估'),
        items: const [
          DropdownMenuItem(
            value: '選項1',
            child: Text('選項1'),
          ),
          DropdownMenuItem(
            value: '選項2',
            child: Text('選項2'),
          ),
          DropdownMenuItem(
            value: '選項3',
            child: Text('選項3'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _abilityEvaluation = value as String;
          });
        },
        value: _abilityEvaluation,
      ),
      DropdownButtonFormField(
        decoration: const InputDecoration(labelText: '物資及獎助學金'),
        items: const [
          DropdownMenuItem(
            value: '選項1',
            child: Text('選項1'),
          ),
          DropdownMenuItem(
            value: '選項2',
            child: Text('選項2'),
          ),
          DropdownMenuItem(
            value: '選項3',
            child: Text('選項3'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _resourcesAndScholarships = value as String;
          });
        },
        value: _resourcesAndScholarships,
      ),
    ]);
  }

  InfoCardLayoutWith2Column _emergencyInfo(StudentDetailState state) {
    return InfoCardLayoutWith2Column(title: "緊急聯絡人", columns1: [
      TextFormField(
        initialValue: _emergencyContactName,
        decoration: const InputDecoration(labelText: '緊急聯絡人姓名'),
        onSaved: (value) => _emergencyContactName = value,
        enabled: !state.isView,
      ),
      TextFormField(
        initialValue: _emergencyContactIdNumber,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '緊急聯絡人身分證'),
        onSaved: (value) => _emergencyContactIdNumber = value,
      ),
      TextFormField(
        initialValue: _emergencyContactCompany,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '緊急聯絡人任職公司/單位'),
        onSaved: (value) => _emergencyContactCompany = value,
      ),
      TextFormField(
        initialValue: _emergencyContactPhone,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '緊急聯絡人電話'),
        onSaved: (value) => _emergencyContactPhone = value,
      ),
      TextFormField(
        initialValue: _emergencyContactEmail,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '緊急聯絡人電子郵件'),
        onSaved: (value) => _emergencyContactEmail = value,
      ),
    ], columns2: [
      Row(
        children: [
          Expanded(
            child: ListTile(
              title: const Text('是否有特殊疾病'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _hasSpecialDisease,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasSpecialDisease = value ?? false;
                      });
                    },
                  ),
                  const Text('是'),
                  Checkbox(
                    value: !_hasSpecialDisease,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasSpecialDisease = !(value ?? true);
                      });
                    },
                  ),
                  const Text('否'),
                ],
              ),
            ),
          ),
          if (_hasSpecialDisease)
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: '特殊疾病描述'),
                onSaved: (value) => _specialDiseaseDescription = value,
                enabled: !state.isView,
              ),
            ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: ListTile(
              title: const Text('是否為特殊學生'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _isSpecialStudent,
                    onChanged: (bool? value) {
                      setState(() {
                        _isSpecialStudent = value ?? false;
                      });
                    },
                  ),
                  const Text('是'),
                  Checkbox(
                    value: !_isSpecialStudent,
                    onChanged: (bool? value) {
                      setState(() {
                        _isSpecialStudent = !(value ?? true);
                      });
                    },
                  ),
                  const Text('否'),
                ],
              ),
            ),
          ),
          if (_isSpecialStudent)
            Expanded(
              child: TextFormField(
                enabled: !state.isView,
                decoration: const InputDecoration(labelText: '特殊學生描述'),
                onSaved: (value) => _specialStudentDescription = value,
              ),
            ),
        ],
      ),
    ]);
  }

  InfoCardLayoutWith2Column _parentsInfo(StudentDetailState state) {
    return InfoCardLayoutWith2Column(title: "法定代理人或監護人", columns1: [
      TextFormField(
        initialValue: _guardianName,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '姓名'),
        onSaved: (value) => _guardianName = value,
      ),
      TextFormField(
        initialValue: _guardianIdNumber,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '身分證'),
        onSaved: (value) => _guardianIdNumber = value,
      ),
      TextFormField(
        initialValue: _guardianCompany,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '任職公司/單位'),
        onSaved: (value) => _guardianCompany = value,
      ),
      TextFormField(
        initialValue: _guardianPhone,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '電話'),
        onSaved: (value) => _guardianPhone = value,
      ),
      TextFormField(
        initialValue: _guardianEmail,
        enabled: !state.isView,
        decoration: const InputDecoration(labelText: '電子郵件'),
        onSaved: (value) => _guardianEmail = value,
      ),
    ], columns2: const []);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
