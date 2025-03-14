import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class YbSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double width;
  final double height;

  const YbSearchField({
    super.key,
    required this.controller,
    this.hintText = '搜尋...',
    this.onChanged,
    this.width = 200,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
        child: TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: FlutterFlowTheme.of(context).bodySmall,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).borderPrimary,
                width: 1,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).borderPrimary,
                width: 1,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 20,
            ),
            fillColor: FlutterFlowTheme.of(context).primaryBackground,
            filled: true,
          ),
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
      ),
    );
  }
} 