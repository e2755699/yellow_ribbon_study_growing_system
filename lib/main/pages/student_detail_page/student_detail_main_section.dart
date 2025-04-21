import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_performance_cubit/student_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
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
      widget.studentDetail.name = _name!;
      widget.studentDetail.classLocation = _classLocation!;
      widget.studentDetail.gender = _gender!;
      widget.studentDetail.phone = _phone!;
      widget.studentDetail.birthday = _birthday!;
      widget.studentDetail.idNumber = _idNumber!;
      widget.studentDetail.school = _school!;
      widget.studentDetail.email = _email!;
      widget.studentDetail.economicStatus = _economicStatus;
      widget.studentDetail.guardianName = _guardianName!;
      widget.studentDetail.guardianIdNumber = _guardianIdNumber!;
      widget.studentDetail.guardianCompany = _guardianCompany!;
      widget.studentDetail.guardianPhone = _guardianPhone!;
      widget.studentDetail.guardianEmail = _guardianEmail!;
      widget.studentDetail.emergencyContactName = _emergencyContactName!;
      widget.studentDetail.description = _description!;
      widget.studentDetail.emergencyContactIdNumber =
          _emergencyContactIdNumber!;
      widget.studentDetail.emergencyContactCompany = _emergencyContactCompany!;
      widget.studentDetail.emergencyContactPhone = _emergencyContactPhone!;
      widget.studentDetail.emergencyContactEmail = _emergencyContactEmail!;
      widget.studentDetail.hasSpecialDisease = _hasSpecialDisease;
      widget.studentDetail.specialDiseaseDescription =
          _specialDiseaseDescription;
      widget.studentDetail.isSpecialStudent = _isSpecialStudent;
      widget.studentDetail.specialStudentDescription =
          _specialStudentDescription;
      widget.studentDetail.needsPickup = _needsPickup;
      widget.studentDetail.pickupRequirementDescription =
          _pickupRequirementDescription;
      widget.studentDetail.familyStatus = _familyStatus;
      widget.studentDetail.ethnicStatus = _ethnicStatus;
      widget.studentDetail.interest = _interest!;
      widget.studentDetail.abilityEvaluation = _abilityEvaluation!;
      widget.studentDetail.learningGoals = _learningGoals!;
      widget.studentDetail.resourcesAndScholarships =
          _resourcesAndScholarships!;
      widget.studentDetail.talentClass = _talentClass!;
      widget.studentDetail.specialCourse = _specialCourse!;
      widget.studentDetail.studentIntroduction = _studentIntroduction!;
      widget.studentDetail.avatar = _avatar;

      // 如果是新学生，使用create方法并获取ID
      if (widget.studentDetail.id == null) {
        final newId =
            await GetIt.instance<StudentsRepo>().create(widget.studentDetail);
        if (newId != null) {
          widget.studentDetail.id = newId;
          _isTemporary = false; // 标记为正式数据
        }
      } else {
        // 如果是现有学生，使用update方法
        await GetIt.instance<StudentsRepo>()
            .update(widget.studentDetail.id!, widget.studentDetail);
        _isTemporary = false; // 标记为正式数据
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
          widget.studentDetail.avatar = fileName;
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
    return BlocBuilder<StudentDetailCubit, StudentDetailState>(
        builder: (context, state) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: FlutterFlowTheme.of(context).spaceXLarge.h),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: state.operate.isView
                      ? () {
                          context.read<StudentDetailCubit>().edit();
                        }
                      : null,
                  child: const Text('編輯'),
                ),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                _saveButton(state),
              ],
            ),
          ),
          // 添加頭像
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                StudentAvatar(
                  avatarFileName: _avatar,
                  size: 120,
                  onAvatarSelected: widget.studentDetail.id != null
                      ? _handleAvatarSelected
                      : (file) {
                          Fluttertoast.showToast(msg: "請先保存學生信息，再上傳頭像");
                        },
                  pendingImageFile: _pendingImageFile,
                  yellowRibbonCount: _yellowRibbonCount,
                ),
                if (_isUploadingAvatar)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: FlutterFlowTheme.of(context).spaceXLarge.h),
              child: Container(
                decoration: buildBoxDecoration(
                    FlutterFlowTheme.of(context).radiusMedium,
                    FlutterFlowTheme.of(context).primaryBackground),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // _personalInfo(context),
                      InfoCardLayoutWith2Column(title: "個人資料", columns1: [
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(labelText: '名字'),
                          onSaved: (value) => _name = value,
                          enabled: !state.isView,
                        ),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: '性別'),
                          items: const [
                            DropdownMenuItem(
                              value: '男',
                              child: Text('男'),
                            ),
                            DropdownMenuItem(
                              value: '女',
                              child: Text('女'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                          value: _gender,
                        ),
                        TextFormField(
                          enabled: !state.isView,
                          decoration: const InputDecoration(labelText: '生日'),
                          controller: TextEditingController(
                            text: _birthday != null
                                ? "${_birthday!.year}/${_birthday!.month}/${_birthday!.day}"
                                : '',
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _birthday ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null && pickedDate != _birthday) {
                              setState(() {
                                _birthday = pickedDate;
                              });
                            }
                          },
                          validator: (value) {
                            if (_birthday == null) {
                              return '請選擇生日';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          initialValue: _idNumber,
                          enabled: !state.isView,
                          decoration: const InputDecoration(labelText: '身分證字號'),
                          onSaved: (value) => _idNumber = value,
                        ),
                        TextFormField(
                          initialValue: _email,
                          enabled: !state.isView,
                          decoration: const InputDecoration(labelText: '電子郵件'),
                          onSaved: (value) => _email = value,
                        ),
                        enumDropdown<EconomicStatus>(
                          value: _economicStatus,
                          onChanged: (value) {
                            setState(() {
                              _economicStatus = value;
                            });
                          },
                          labelText: '經濟狀況',
                          enumValues: EconomicStatus.values,
                          getDisplayName: (status) {
                            switch (status) {
                              case EconomicStatus.normal:
                                return '一般';
                              case EconomicStatus.mediumLowIncome:
                                return '中低收入戶';
                              case EconomicStatus.lowIncome:
                                return '低收入戶';
                            }
                          },
                          enabled: !state.isView,
                        ),
                      ], columns2: [
                        TextFormField(
                          initialValue: _phone,
                          decoration: const InputDecoration(labelText: '電話'),
                          onSaved: (value) => _phone = value,
                          enabled: !state.isView,
                        ),
                        TextFormField(
                          initialValue: _school,
                          decoration: const InputDecoration(labelText: '學校'),
                          onSaved: (value) => _school = value,
                          enabled: !state.isView,
                        ),
                        DropdownButtonFormField(
                          decoration: const InputDecoration(labelText: '據點'),
                          items: [
                            ...ClassLocation.values
                                .map((classLocation) => DropdownMenuItem(
                                      value: classLocation.name,
                                      child: Text(classLocation.name),
                                    )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _classLocation = value;
                            });
                          },
                          value: _classLocation,
                        ),
                        enumDropdown<FamilyStatus>(
                          value: _familyStatus,
                          onChanged: (value) {
                            setState(() {
                              _familyStatus = value;
                            });
                          },
                          labelText: '家庭狀況',
                          enumValues: FamilyStatus.values,
                          getDisplayName: (status) {
                            switch (status) {
                              case FamilyStatus.bothParents:
                                return '雙親';
                              case FamilyStatus.singleParentWithFather:
                                return '單親與父同住';
                              case FamilyStatus.singleParentWithMother:
                                return '單親與母同住';
                              case FamilyStatus.grandparentCare:
                                return '隔代教養';
                            }
                          },
                          enabled: !state.isView,
                        ),
                        enumDropdown<EthnicStatus>(
                          value: _ethnicStatus,
                          onChanged: (value) {
                            setState(() {
                              _ethnicStatus = value;
                            });
                          },
                          labelText: '是否原住民',
                          enumValues: EthnicStatus.values,
                          getDisplayName: (status) {
                            switch (status) {
                              case EthnicStatus.none:
                                return '非原住民/新住民';
                              case EthnicStatus.indigenous:
                                return '原住民';
                              case EthnicStatus.newResident:
                                return '新住民';
                            }
                          },
                          enabled: !state.isView,
                        ),
                      ]),
                      _parentsInfo(state),
                      _emergencyInfo(state),
                      _otherInfo(state),
                      InfoCardLayoutWith1Column(
                        title: "學生簡介",
                        columns1: [
                          TextFormField(
                            enabled: !state.isView,
                            initialValue: _studentIntroduction,
                            maxLines: 10,
                            minLines: 5,
                            decoration: const InputDecoration(
                              hintText: '請輸入學生簡介（至少可輸入300字）',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) => _studentIntroduction = value,
                          ),
                        ],
                      ),
                      InfoCardLayoutWith1Column(
                        title: "表現描述",
                        columns1: [
                          TextFormField(
                            enabled: !state.isView,
                            initialValue: _description,
                            decoration: const InputDecoration(labelText: ''),
                            onSaved: (value) => _description = value,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  ElevatedButton _saveButton(StudentDetailState state) {
    return ElevatedButton(
      onPressed: !state.operate.isView ? _submitForm : null,
      child: const Text('儲存'),
    );
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
