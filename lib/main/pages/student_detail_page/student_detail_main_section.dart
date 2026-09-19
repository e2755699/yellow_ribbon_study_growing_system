import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:yellow_ribbon_study_growing_system/domain/service/student_attachment_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import '../../../design_system/presentation/system_theme.dart';
import 'student_profile_overview.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
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
  final StudentDetail studentDetail;

  const StudentDetailMainSection({super.key, required this.studentDetail});

  @override
  State<StudentDetailMainSection> createState() =>
      StudentDetailMainSectionState();
}

class StudentDetailMainSectionState extends State<StudentDetailMainSection>
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
  late String _motto;
  String? _avatar;
  String? _profileFileName;
  final StorageService _storageService = StorageService();
  bool _isUploadingAvatar = false;
  bool _isUploadingProfile = false;
  XFile? _pendingImageFile;
  int _yellowRibbonCount = 0;
  bool _isSaving = false;
  bool get isBusy => _isSaving || _isUploadingAvatar || _isUploadingProfile;
  late final _attachments = StudentAttachmentService(
      students: GetIt.I<StudentsRepo>(), storage: _storageService);

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
    _motto = widget.studentDetail.motto;
    _avatar = widget.studentDetail.avatar;
    _profileFileName = widget.studentDetail.profileFileName;
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

  /// 獲取當前表單資料並驗證，供外部調用
  Future<StudentDetail?> getFormDataIfValid() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      return StudentDetail(
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
        motto: _motto,
        avatar: _avatar,
        profileFileName: _profileFileName,
      );
    }
    return null; // 驗證失敗
  }

  Future<bool> saveForm() async {
    if (isBusy) return false;
    setState(() => _isSaving = true);
    try {
      final detail = await getFormDataIfValid();
      if (detail == null || !mounted) return false;
      return await context.read<StudentDetailCubit>().save(detail);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForm() async {
    if (await saveForm() && mounted) {
      Fluttertoast.showToast(msg: '學生資料已儲存');
    }
  }

  Future<void> _handleAvatarSelected(XFile imageFile) async {
    if (isBusy || widget.studentDetail.id == null) return;
    final cubit = context.read<StudentDetailCubit>();
    setState(() {
      _pendingImageFile = imageFile;
      _isUploadingAvatar = true;
    });
    try {
      final result = await _attachments.replaceAvatar(
          widget.studentDetail.id!, _avatar, imageFile);
      if (!mounted) return;
      setState(() => _avatar = result.fileName);
      cubit.syncAvatar(result.fileName);
      Fluttertoast.showToast(
          msg: result.cleanupFailed ? '頭像已更新，舊檔案清理失敗' : '頭像上傳成功');
    } catch (error) {
      if (mounted) Fluttertoast.showToast(msg: error.toString());
    } finally {
      if (mounted)
        setState(() {
          _pendingImageFile = null;
          _isUploadingAvatar = false;
        });
    }
  }

  Future<void> _handleProfileFileSelected() async {
    if (isBusy) return;
    if (widget.studentDetail.id == null) {
      Fluttertoast.showToast(msg: '請先儲存學生資料，再上傳個人檔案');
      return;
    }
    final cubit = context.read<StudentDetailCubit>();
    setState(() => _isUploadingProfile = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: kIsWeb,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (picked == null || picked.files.isEmpty || !mounted) return;
      final result = await _attachments.replaceProfile(
          widget.studentDetail.id!, _profileFileName, picked.files.first);
      if (!mounted) return;
      setState(() => _profileFileName = result.fileName);
      cubit.syncProfileFile(result.fileName);
      Fluttertoast.showToast(
          msg: result.cleanupFailed ? '個人檔案已更新，舊檔案清理失敗' : '個人檔案上傳成功');
    } catch (error) {
      if (mounted) Fluttertoast.showToast(msg: error.toString());
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  // 下載／開啟個人檔案
  Future<void> _downloadProfileFile() async {
    if (_profileFileName == null || _profileFileName!.isEmpty) return;

    final url = await _storageService.getProfileFileUrl(_profileFileName);
    if (url == null) {
      Fluttertoast.showToast(msg: "無法取得檔案連結");
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: "無法開啟檔案");
    }
  }

  // 刪除個人檔案
  Future<void> _deleteProfileFile() async {
    if (_profileFileName == null || _profileFileName!.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除個人檔案'),
        content: const Text('確定要刪除個人檔案嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('刪除',
                style:
                    TextStyle(color: SystemTheme.of(context).color('error'))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted || isBusy || widget.studentDetail.id == null) return;
    final cubit = context.read<StudentDetailCubit>();
    setState(() => _isUploadingProfile = true);
    try {
      await _attachments.deleteProfile(
          widget.studentDetail.id!, _profileFileName!);
      if (!mounted) return;
      setState(() => _profileFileName = null);
      cubit.syncProfileFile(null);
      Fluttertoast.showToast(msg: '個人檔案已刪除');
    } catch (error) {
      if (mounted) Fluttertoast.showToast(msg: error.toString());
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentDetailCubit, StudentDetailState>(
        builder: (context, state) {
      if (state.isView) {
        return Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: BlocBuilder<StudentActivityCubit, StudentActivityState>(
            builder: (context, activity) => StudentProfileOverview(
              student: state.detail,
              activity: activity,
              ribbonCount: _yellowRibbonCount,
              onEdit: () => context.read<StudentDetailCubit>().edit(),
              onHistory: state.detail.id == null
                  ? null
                  : () async {
                      await context.push(
                          '/studentHistoryPerformance/${state.detail.id}');
                      if (context.mounted) {
                        context.read<StudentActivityCubit>().load();
                      }
                    },
              onRetry: () => context.read<StudentActivityCubit>().load(),
              attachment: _profileFileSection(state),
            ),
          ),
        ));
      }
      return Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBar(context, state),
                  Expanded(child: _infoSection(context, state)),
                ],
              )));
    });
  }

  Widget _infoSection(BuildContext context, StudentDetailState state) {
    return ListView(
      children: [
        // 添加頭像
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              StudentAvatar(
                avatarFileName: _avatar,
                gender: _gender,
                size: 120,
                backgroundColor: SystemTheme.of(context).accentSurface,
                onAvatarSelected: isBusy || state.isView
                    ? null
                    : widget.studentDetail.id != null
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
        Padding(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: buildBoxDecoration(
                  FlutterFlowTheme.of(context).radiusMedium,
                  Colors.transparent),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // _personalInfo(context),
                    InfoCardLayoutWith2Column(title: "個人資料", columns1: [
                      TextFormField(
                        initialValue: _name,
                        decoration: const InputDecoration(labelText: '名字'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '請輸入學生姓名'
                                : null,
                        onSaved: (value) => _name = value,
                        enabled: !state.isView && !isBusy,
                      ),
                      TextFormField(
                        key: const Key('student-motto-input'),
                        initialValue: _motto,
                        decoration: const InputDecoration(
                          labelText: '座右銘',
                          hintText: StudentDetail.defaultMotto,
                          helperText: '留白時顯示「${StudentDetail.defaultMotto}」',
                          helperMaxLines: 2,
                        ),
                        minLines: 1,
                        maxLines: 3,
                        onSaved: (value) => _motto = value?.trim() ?? '',
                        enabled: !state.isView && !isBusy,
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
                        onChanged: state.isView || isBusy
                            ? null
                            : (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                        value: _gender,
                      ),
                      TextFormField(
                        enabled: !state.isView && !isBusy,
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
                        enabled: !state.isView && !isBusy,
                        decoration: const InputDecoration(labelText: '身分證字號'),
                        onSaved: (value) => _idNumber = value,
                      ),
                      TextFormField(
                        initialValue: _email,
                        enabled: !state.isView && !isBusy,
                        decoration: const InputDecoration(labelText: '電子郵件'),
                        onSaved: (value) => _email = value,
                      ),
                      enumDropdown<EconomicStatus>(
                        value: _economicStatus,
                        onChanged: state.isView || isBusy
                            ? null
                            : (value) {
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
                        enabled: !state.isView && !isBusy,
                      ),
                    ], columns2: [
                      TextFormField(
                        initialValue: _phone,
                        decoration: const InputDecoration(labelText: '電話'),
                        onSaved: (value) => _phone = value,
                        enabled: !state.isView && !isBusy,
                      ),
                      TextFormField(
                        initialValue: _school,
                        decoration: const InputDecoration(labelText: '學校'),
                        onSaved: (value) => _school = value,
                        enabled: !state.isView && !isBusy,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '據點'),
                        items: [
                          ...ClassLocation.values
                              .map((classLocation) => DropdownMenuItem(
                                    value: classLocation.name,
                                    child: Text(classLocation.name),
                                  )),
                        ],
                        onChanged: state.isView || isBusy
                            ? null
                            : (value) {
                                setState(() {
                                  _classLocation = value;
                                });
                              },
                        value: _classLocation,
                      ),
                      enumDropdown<FamilyStatus>(
                        value: _familyStatus,
                        onChanged: state.isView || isBusy
                            ? null
                            : (value) {
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
                        enabled: !state.isView && !isBusy,
                      ),
                      enumDropdown<EthnicStatus>(
                        value: _ethnicStatus,
                        onChanged: state.isView || isBusy
                            ? null
                            : (value) {
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
                        enabled: !state.isView && !isBusy,
                      ),
                    ]),
                    _parentsInfo(state),
                    _emergencyInfo(state),
                    _otherInfo(state),
                    InfoCardLayoutWith1Column(
                      title: "學生簡介",
                      columns1: [
                        TextFormField(
                          enabled: !state.isView && !isBusy,
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
                          enabled: !state.isView && !isBusy,
                          initialValue: _description,
                          decoration: const InputDecoration(labelText: ''),
                          onSaved: (value) => _description = value,
                        ),
                      ],
                    ),
                    _profileFileSection(state),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileFileSection(StudentDetailState state) {
    final hasFile = _profileFileName != null && _profileFileName!.isNotEmpty;

    return InfoCardLayoutWith1Column(
      title: "個人檔案",
      titleSuffix: !state.isView
          ? ElevatedButton.icon(
              onPressed: isBusy ? null : _handleProfileFileSelected,
              icon: const Icon(Icons.upload_file),
              label: const Text('上傳檔案'),
            )
          : null,
      columns1: [
        if (_isUploadingProfile)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasFile)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.description_outlined,
                    size: 28, color: SystemTheme.of(context).color('detail')),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _profileFileName!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _downloadProfileFile,
                  icon: const Icon(Icons.download),
                  label: const Text('開啟'),
                ),
                if (!state.isView)
                  TextButton.icon(
                    onPressed: isBusy ? null : _deleteProfileFile,
                    icon: Icon(Icons.delete_outline,
                        color: SystemTheme.of(context).color('error')),
                    label: Text('刪除',
                        style: TextStyle(
                            color: SystemTheme.of(context).color('error'))),
                  ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              '尚未上傳個人檔案',
              style: TextStyle(
                  color: SystemTheme.of(context).color('secondaryText')),
            ),
          ),
      ],
    );
  }

  Widget _actionBar(BuildContext context, StudentDetailState state) {
    return Container(
      decoration: SystemTheme.of(context).cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
              child: Text(state.isCreate ? '建立學生檔案' : '編輯學生資料',
                  style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: !isBusy && !state.operate.isView ? _submitForm : null,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(_isSaving ? '儲存中…' : '儲存'),
          ),
        ],
      ),
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
        onChanged: state.isView || isBusy
            ? null
            : (value) {
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
        enabled: !state.isView && !isBusy,
      ),
      TextFormField(
        initialValue: _specialCourse,
        decoration: const InputDecoration(labelText: '特殊課程'),
        onSaved: (value) => _specialCourse = value,
        enabled: !state.isView && !isBusy,
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
        onChanged: state.isView || isBusy
            ? null
            : (value) {
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
            child: Material(
              child: ListTile(
                title: const Text('是否需要接送'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _needsPickup,
                      onChanged: state.isView || isBusy
                          ? null
                          : (bool? value) {
                              setState(() {
                                _needsPickup = value ?? false;
                              });
                            },
                    ),
                    const Text('是'),
                    Checkbox(
                      value: !_needsPickup,
                      onChanged: state.isView || isBusy
                          ? null
                          : (bool? value) {
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
          ),
          // if (_needsPickup)
          //   Expanded(
          //     child: TextFormField(
          //       initialValue: _pickupRequirementDescription,
          //       enabled: !state.isView && !isBusy,
          //       decoration: const InputDecoration(labelText: '接送需求描述'),
          //       onSaved: (value) => _pickupRequirementDescription = value,
          //     ),
          //   ),
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
        onChanged: state.isView || isBusy
            ? null
            : (value) {
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
        onChanged: state.isView || isBusy
            ? null
            : (value) {
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
        enabled: !state.isView && !isBusy,
      ),
      TextFormField(
        initialValue: _emergencyContactIdNumber,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '緊急聯絡人身分證'),
        onSaved: (value) => _emergencyContactIdNumber = value,
      ),
      TextFormField(
        initialValue: _emergencyContactCompany,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '緊急聯絡人任職公司/單位'),
        onSaved: (value) => _emergencyContactCompany = value,
      ),
      TextFormField(
        initialValue: _emergencyContactPhone,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '緊急聯絡人電話'),
        onSaved: (value) => _emergencyContactPhone = value,
      ),
      TextFormField(
        initialValue: _emergencyContactEmail,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '緊急聯絡人電子郵件'),
        onSaved: (value) => _emergencyContactEmail = value,
      ),
    ], columns2: [
      Row(
        children: [
          Expanded(
            child: Material(
              child: ListTile(
                title: const Text('是否有特殊疾病'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _hasSpecialDisease,
                      onChanged: state.isView || isBusy
                          ? null
                          : (bool? value) {
                              setState(() {
                                _hasSpecialDisease = value ?? false;
                              });
                            },
                    ),
                    const Text('是'),
                    Checkbox(
                      value: !_hasSpecialDisease,
                      onChanged: state.isView || isBusy
                          ? null
                          : (bool? value) {
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
          ),
          // if (_hasSpecialDisease)
          //   Expanded(
          //     child: TextFormField(
          //       decoration: const InputDecoration(labelText: '特殊疾病描述'),
          //       onSaved: (value) => _specialDiseaseDescription = value,
          //       enabled: !state.isView && !isBusy,
          //     ),
          //   ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: Material(
              child: ListTile(
                title: const Text('是否為特殊學生'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _isSpecialStudent,
                      onChanged: state.isView || isBusy
                          ? null
                          : (bool? value) {
                              setState(() {
                                _isSpecialStudent = value ?? false;
                              });
                            },
                    ),
                    const Text('是'),
                    Checkbox(
                      value: !_isSpecialStudent,
                      onChanged: state.isView || isBusy
                          ? null
                          : (bool? value) {
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
          ),
          // if (_isSpecialStudent)
          //   Expanded(
          //     child: TextFormField(
          //       enabled: !state.isView && !isBusy,
          //       decoration: const InputDecoration(labelText: '特殊學生描述'),
          //       onSaved: (value) => _specialStudentDescription = value,
          //     ),
          //   ),
        ],
      ),
    ]);
  }

  InfoCardLayoutWith2Column _parentsInfo(StudentDetailState state) {
    return InfoCardLayoutWith2Column(title: "法定代理人或監護人", columns1: [
      TextFormField(
        initialValue: _guardianName,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '姓名'),
        onSaved: (value) => _guardianName = value,
      ),
      TextFormField(
        initialValue: _guardianIdNumber,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '身分證'),
        onSaved: (value) => _guardianIdNumber = value,
      ),
      TextFormField(
        initialValue: _guardianCompany,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '任職公司/單位'),
        onSaved: (value) => _guardianCompany = value,
      ),
      TextFormField(
        initialValue: _guardianPhone,
        enabled: !state.isView && !isBusy,
        decoration: const InputDecoration(labelText: '電話'),
        onSaved: (value) => _guardianPhone = value,
      ),
      TextFormField(
        initialValue: _guardianEmail,
        enabled: !state.isView && !isBusy,
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
