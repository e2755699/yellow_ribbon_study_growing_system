import 'package:flutter/material.dart';

/// Keeps focus/selection when remote data or sibling rows change.
class RecordTextField extends StatefulWidget {
  final String value, label;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  const RecordTextField(
      {super.key,
      required this.value,
      required this.label,
      this.onChanged,
      this.maxLines = 2});
  @override
  State<RecordTextField> createState() => _RecordTextFieldState();
}

class _RecordTextFieldState extends State<RecordTextField> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(covariant RecordTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller.text != widget.value) {
      final offset =
          controller.selection.baseOffset.clamp(0, widget.value.length);
      controller.value = TextEditingValue(
          text: widget.value,
          selection: TextSelection.collapsed(offset: offset));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
      controller: controller,
      enabled: widget.onChanged != null,
      maxLines: widget.maxLines,
      maxLength: 4000,
      decoration: InputDecoration(labelText: widget.label, counterText: ''),
      onChanged: widget.onChanged);
}
