import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/model/bloc/student_cubit/student_detail.dart';

class StudentDetailMainSection extends StatefulWidget {
  late StudentDetail studentDetail;

  StudentDetailMainSection({super.key, required this.studentDetail});

  @override
  State<StudentDetailMainSection> createState() =>
      _StudentDetailMainSectionState();
}

class _StudentDetailMainSectionState extends State<StudentDetailMainSection> {
  //student info
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _gender;
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

  String? _parentStatus;
  String? _familyStatus;
  String? _interest;
  String? _personality;
  String? _mentalStatus;
  String? _socialSkills;
  String? _abilityEvaluation;
  String? _learningGoals;
  String? _resourcesAndScholarships;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Here you can replace this print statement with functionality to store data in a database or perform other actions.
      print('名字：$_name');
      print('性別：$_gender');
      print('電話：$_phone');
      print('生日：$_birthday');
      print('身分證字號：$_idNumber');
      print('學校：$_school');
      print('電子郵件：$_email');
      print('父親姓名：$_fatherName');
      print('父親身分證：$_fatherIdNumber');
      print('父親任職公司/單位：$_fatherCompany');
      print('父親電話：$_fatherPhone');
      print('父親電子郵件：$_fatherEmail');
      print('母親姓名：$_motherName');
      print('母親身分證：$_motherIdNumber');
      print('母親任職公司/單位：$_motherCompany');
      print('母親電話：$_motherPhone');
      print('母親電子郵件：$_motherEmail');
      print('緊急聯絡人姓名：$_emergencyContactName');
      print('緊急聯絡人身分證：$_emergencyContactIdNumber');
      print('緊急聯絡人任職公司/單位：$_emergencyContactCompany');
      print('緊急聯絡人電話：$_emergencyContactPhone');
      print('緊急聯絡人電子郵件：$_emergencyContactEmail');
      print('是否有特殊疾病：$_hasSpecialDisease');
      if (_hasSpecialDisease) {
        print('特殊疾病描述：$_specialDiseaseDescription');
      }
      print('是否為特殊學生：$_isSpecialStudent');
      if (_isSpecialStudent) {
        print('特殊學生描述：$_specialStudentDescription');
      }
      print('是否需要接送：$_needsPickup');
      if (_needsPickup) {
        print('接送需求描述：$_pickupRequirementDescription');
      }
      print('雙親狀況：$_parentStatus');
      print('家庭狀況：$_familyStatus');
      print('興趣：$_interest');
      print('個性：$_personality');
      print('身心狀態：$_mentalStatus');
      print('社交技巧：$_socialSkills');
      print('能力評估：$_abilityEvaluation');
      print('學習目標：$_learningGoals');
      print('物資及獎助學金：$_resourcesAndScholarships');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _infoSection(context);
  }

  Widget _infoSection(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Other form fields
            TextFormField(
              decoration: InputDecoration(labelText: '名字'),
              onSaved: (value) => _name = value,
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
              decoration: InputDecoration(labelText: '電話'),
              onSaved: (value) => _phone = value,
            ),
            TextFormField(
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
              decoration: InputDecoration(labelText: '身分證字號'),
              onSaved: (value) => _idNumber = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '學校'),
              onSaved: (value) => _school = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '電子郵件'),
              onSaved: (value) => _email = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '父親姓名'),
              onSaved: (value) => _fatherName = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '父親身分證'),
              onSaved: (value) => _fatherIdNumber = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '父親任職公司/單位'),
              onSaved: (value) => _fatherCompany = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '父親電話'),
              onSaved: (value) => _fatherPhone = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '父親電子郵件'),
              onSaved: (value) => _fatherEmail = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '母親姓名'),
              onSaved: (value) => _motherName = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '母親身分證'),
              onSaved: (value) => _motherIdNumber = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '母親任職公司/單位'),
              onSaved: (value) => _motherCompany = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '母親電話'),
              onSaved: (value) => _motherPhone = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '母親電子郵件'),
              onSaved: (value) => _motherEmail = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '緊急聯絡人姓名'),
              onSaved: (value) => _emergencyContactName = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '緊急聯絡人身分證'),
              onSaved: (value) => _emergencyContactIdNumber = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '緊急聯絡人任職公司/單位'),
              onSaved: (value) => _emergencyContactCompany = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '緊急聯絡人電話'),
              onSaved: (value) => _emergencyContactPhone = value,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '緊急聯絡人電子郵件'),
              onSaved: (value) => _emergencyContactEmail = value,
            ),
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
                      decoration: InputDecoration(labelText: '特殊學生描述'),
                      onSaved: (value) => _specialStudentDescription = value,
                    ),
                  ),
              ],
            ),
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
                      decoration: InputDecoration(labelText: '接送需求描述'),
                      onSaved: (value) => _pickupRequirementDescription = value,
                    ),
                  ),
              ],
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: '雙親狀況'),
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
                  _parentStatus = value as String;
                });
              },
              value: _parentStatus,
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: '家庭狀況'),
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
                  _familyStatus = value as String;
                });
              },
              value: _familyStatus,
            ),
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
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('送出'),
            ),
          ],
        ),
      ),
    );
  }
}



