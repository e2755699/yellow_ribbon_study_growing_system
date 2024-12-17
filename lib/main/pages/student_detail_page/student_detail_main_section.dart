import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
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
  String? _fatherName;
  String? _fatherIdNumber;
  String? _fatherCompany;
  String? _fatherPhone;
  String? _fatherEmail;
  String? _motherName;
  String? _motherIdNumber;
  String? _motherCompany;
  String? _motherPhone;
  String? _motherEmail;
  String? _emergencyContactName;
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
  String? _description;

  late FamilyStatus _familyStatus;
  String? _interest;
  String? _personality;
  String? _mentalStatus;
  String? _socialSkills;
  String? _abilityEvaluation;
  String? _learningGoals;
  String? _resourcesAndScholarships;

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
    _fatherName = widget.studentDetail.fatherName;
    _fatherIdNumber = widget.studentDetail.fatherIdNumber;
    _fatherCompany = widget.studentDetail.fatherCompany;
    _fatherPhone = widget.studentDetail.fatherPhone;
    _fatherEmail = widget.studentDetail.fatherEmail;
    _motherName = widget.studentDetail.motherName;
    _motherIdNumber = widget.studentDetail.motherIdNumber;
    _motherCompany = widget.studentDetail.motherCompany;
    _motherPhone = widget.studentDetail.motherPhone;
    _motherEmail = widget.studentDetail.motherEmail;
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
    _interest = widget.studentDetail.interest;
    _personality = widget.studentDetail.personality;
    _mentalStatus = widget.studentDetail.mentalStatus;
    _socialSkills = widget.studentDetail.socialSkills;
    _abilityEvaluation = widget.studentDetail.abilityEvaluation;
    _learningGoals = widget.studentDetail.learningGoals;
    _resourcesAndScholarships = widget.studentDetail.resourcesAndScholarships;
  }

  void _submitForm() {
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
      widget.studentDetail.fatherName = _fatherName!;
      widget.studentDetail.fatherIdNumber = _fatherIdNumber!;
      widget.studentDetail.fatherCompany = _fatherCompany!;
      widget.studentDetail.fatherPhone = _fatherPhone!;
      widget.studentDetail.fatherEmail = _fatherEmail!;
      widget.studentDetail.motherName = _motherName!;
      widget.studentDetail.motherIdNumber = _motherIdNumber!;
      widget.studentDetail.motherCompany = _motherCompany!;
      widget.studentDetail.motherPhone = _motherPhone!;
      widget.studentDetail.motherEmail = _motherEmail!;
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
      widget.studentDetail.interest = _interest!;
      widget.studentDetail.personality = _personality!;
      widget.studentDetail.mentalStatus = _mentalStatus!;
      widget.studentDetail.socialSkills = _socialSkills!;
      widget.studentDetail.abilityEvaluation = _abilityEvaluation!;
      widget.studentDetail.learningGoals = _learningGoals!;
      widget.studentDetail.resourcesAndScholarships =
          _resourcesAndScholarships!;
      context.read<StudentDetailCubit>().save(widget.studentDetail);
    } else {
      Fluttertoast.showToast(msg: "form error , please check form!");
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
                  child: Text('編輯'),
                ),
                Gap(FlutterFlowTheme.of(context).spaceMedium),
                _saveButton(state),
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
                          decoration: InputDecoration(labelText: '名字'),
                          onSaved: (value) => _name = value,
                          enabled: !state.isView,
                        ),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: '性別'),
                          items: [
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
                          decoration: InputDecoration(labelText: '生日'),
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
                            if (pickedDate != null && pickedDate != _birthday)
                              setState(() {
                                _birthday = pickedDate;
                              });
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
                          decoration: InputDecoration(labelText: '身分證字號'),
                          onSaved: (value) => _idNumber = value,
                        ),
                        TextFormField(
                          initialValue: _email,
                          enabled: !state.isView,
                          decoration: InputDecoration(labelText: '電子郵件'),
                          onSaved: (value) => _email = value,
                        ),
                      ], columns2: [
                        TextFormField(
                          initialValue: _phone,
                          decoration: InputDecoration(labelText: '電話'),
                          onSaved: (value) => _phone = value,
                          enabled: !state.isView,
                        ),
                        TextFormField(
                          initialValue: _school,
                          decoration: InputDecoration(labelText: '學校'),
                          onSaved: (value) => _school = value,
                          enabled: !state.isView,
                        ),
                        DropdownButtonFormField(
                          decoration: InputDecoration(labelText: '據點'),
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
                        FamilyStatusDropdown(
                            familyStatus: widget.studentDetail.familyStatus),
                      ]),
                      _parentsInfo(state),
                      _emergencyInfo(state),
                      _otherInfo(state),
                      InfoCardLayoutWith1Column(
                        title: "備註",
                        columns1: [
                          TextFormField(
                            enabled: !state.isView,
                            initialValue: _description,
                            decoration: InputDecoration(labelText: ''),
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
                child: Text('儲存'),
              );
  }

  InfoCardLayoutWith2Column _otherInfo(StudentDetailState state) {
    return InfoCardLayoutWith2Column(title: "其他", columns1: [
      DropdownButtonFormField(
        decoration: InputDecoration(labelText: '興趣'),
        items: [
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
      DropdownButtonFormField(
        decoration: InputDecoration(labelText: '個性'),
        items: [
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
            _personality = value as String;
          });
        },
        value: _personality,
      ),
      DropdownButtonFormField(
        decoration: InputDecoration(labelText: '社交技巧'),
        items: [
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
            _socialSkills = value as String;
          });
        },
        value: _socialSkills,
      ),
      DropdownButtonFormField(
        decoration: InputDecoration(labelText: '學習目標'),
        items: [
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
              title: Text('是否需要接送'),
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
                  Text('是'),
                  Checkbox(
                    value: !_needsPickup,
                    onChanged: (bool? value) {
                      setState(() {
                        _needsPickup = !(value ?? true);
                      });
                    },
                  ),
                  Text('否'),
                ],
              ),
            ),
          ),
          if (_needsPickup)
            Expanded(
              child: TextFormField(
                initialValue: _pickupRequirementDescription,
                enabled: !state.isView,
                decoration: InputDecoration(labelText: '接送需求描述'),
                onSaved: (value) => _pickupRequirementDescription = value,
              ),
            ),
        ],
      ),
      DropdownButtonFormField(
        decoration: InputDecoration(labelText: '身心狀態'),
        items: [
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
            _mentalStatus = value as String;
          });
        },
        value: _mentalStatus,
      ),
      DropdownButtonFormField(
        decoration: InputDecoration(labelText: '能力評估'),
        items: [
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
        decoration: InputDecoration(labelText: '物資及獎助學金'),
        items: [
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
        decoration: InputDecoration(labelText: '緊急聯絡人姓名'),
        onSaved: (value) => _emergencyContactName = value,
        enabled: !state.isView,
      ),
      TextFormField(
        initialValue: _emergencyContactIdNumber,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '緊急聯絡人身分證'),
        onSaved: (value) => _emergencyContactIdNumber = value,
      ),
      TextFormField(
        initialValue: _emergencyContactCompany,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '緊急聯絡人任職公司/單位'),
        onSaved: (value) => _emergencyContactCompany = value,
      ),
      TextFormField(
        initialValue: _emergencyContactPhone,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '緊急聯絡人電話'),
        onSaved: (value) => _emergencyContactPhone = value,
      ),
      TextFormField(
        initialValue: _emergencyContactEmail,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '緊急聯絡人電子郵件'),
        onSaved: (value) => _emergencyContactEmail = value,
      ),
    ], columns2: [
      Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text('是否有特殊疾病'),
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
                  Text('是'),
                  Checkbox(
                    value: !_hasSpecialDisease,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasSpecialDisease = !(value ?? true);
                      });
                    },
                  ),
                  Text('否'),
                ],
              ),
            ),
          ),
          if (_hasSpecialDisease)
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(labelText: '特殊疾病描述'),
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
              title: Text('是否為特殊學生'),
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
                  Text('是'),
                  Checkbox(
                    value: !_isSpecialStudent,
                    onChanged: (bool? value) {
                      setState(() {
                        _isSpecialStudent = !(value ?? true);
                      });
                    },
                  ),
                  Text('否'),
                ],
              ),
            ),
          ),
          if (_isSpecialStudent)
            Expanded(
              child: TextFormField(
                enabled: !state.isView,
                decoration: InputDecoration(labelText: '特殊學生描述'),
                onSaved: (value) => _specialStudentDescription = value,
              ),
            ),
        ],
      ),
    ]);
  }

  InfoCardLayoutWith2Column _parentsInfo(StudentDetailState state) {
    return InfoCardLayoutWith2Column(title: "法定代理人", columns1: [
      TextFormField(
        initialValue: _fatherName,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '父親姓名'),
        onSaved: (value) => _fatherName = value,
      ),
      TextFormField(
        initialValue: _fatherIdNumber,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '父親身分證'),
        onSaved: (value) => _fatherIdNumber = value,
      ),
      TextFormField(
        initialValue: _fatherCompany,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '父親任職公司/單位'),
        onSaved: (value) => _fatherCompany = value,
      ),
      TextFormField(
        initialValue: _fatherPhone,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '父親電話'),
        onSaved: (value) => _fatherPhone = value,
      ),
      TextFormField(
        initialValue: _fatherEmail,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '父親電子郵件'),
        onSaved: (value) => _fatherEmail = value,
      ),
    ], columns2: [
      TextFormField(
        initialValue: _motherName,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '母親姓名'),
        onSaved: (value) => _motherName = value,
      ),
      TextFormField(
        initialValue: _motherIdNumber,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '母親身分證'),
        onSaved: (value) => _motherIdNumber = value,
      ),
      TextFormField(
        initialValue: _motherCompany,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '母親任職公司/單位'),
        onSaved: (value) => _motherCompany = value,
      ),
      TextFormField(
        initialValue: _motherPhone,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '母親電話'),
        onSaved: (value) => _motherPhone = value,
      ),
      TextFormField(
        initialValue: _motherEmail,
        enabled: !state.isView,
        decoration: InputDecoration(labelText: '母親電子郵件'),
        onSaved: (value) => _motherEmail = value,
      ),
    ]);
  }
}

class FamilyStatusDropdown extends StatelessWidget {
  FamilyStatus _familyStatus;

  FamilyStatusDropdown({super.key, required FamilyStatus familyStatus})
      : _familyStatus = familyStatus;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FamilyStatus>(
      decoration: InputDecoration(labelText: '家庭狀況'),
      items: [
        DropdownMenuItem(
          value: FamilyStatus.bothParents,
          child: Text('雙親'),
        ),
        DropdownMenuItem(
          value: FamilyStatus.singleParentWithFather,
          child: Text('單親與父同住'),
        ),
        DropdownMenuItem(
          value: FamilyStatus.singleParentWithMother,
          child: Text('單親與母同住'),
        ),
        DropdownMenuItem(
          value: FamilyStatus.grandparentCare,
          child: Text('隔代教養'),
        ),
      ],
      onChanged: (value) {
        _familyStatus = value!;
      },
      value: _familyStatus,
    );
  }
}
