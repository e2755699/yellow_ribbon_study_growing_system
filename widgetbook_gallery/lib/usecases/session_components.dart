import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/main/components/login/sign_out_button.dart';
import '../gallery_environment.dart';

@widgetbook.UseCase(name: 'Sign out', type: SignOutButton)
Widget signOut(BuildContext context) => ProductPreview(
    builder: (context) => Center(
        child: SignOutButton(
            onPressed: () => previewAction(context, '登出展示，不連線'))));

@widgetbook.UseCase(name: 'Signing out', type: SignOutButton)
Widget signingOut(BuildContext context) => ProductPreview(
    builder: (_) =>
        const Center(child: SignOutButton(onPressed: null, busy: true)));

@widgetbook.UseCase(name: 'Disabled sign out', type: SignOutButton)
Widget disabledSignOut(BuildContext context) => ProductPreview(
    builder: (_) => const Center(child: SignOutButton(onPressed: null)));
