import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/yb_button.dart';

class CreateButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CreateButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return YbButton(
        icon: const Icon(Icons.add), text: "新增學生資料", onPressed: onPressed);
  }
}
