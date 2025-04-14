// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:flutter/material.dart';
// 暂时注释掉有问题的导入
// import 'package:widgetbook_gallery/usecases/page/student_info_detail.dart' as _i2;

// 添加一个简单的占位函数
Widget _placeholderBuilder(BuildContext context) {
  return Container(
    child: const Center(
      child: Text('MainScreen Placeholder'),
    ),
  );
}

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'page',
    children: [
      _i1.WidgetbookLeafComponent(
        name: 'MainScreen',
        useCase: _i1.WidgetbookUseCase(
          name: 'main page',
          builder: _placeholderBuilder,
        ),
      )
    ],
  )
];
