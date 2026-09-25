import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_widgets.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

@widgetbook.UseCase(name: 'Primary Button', type: FFButtonWidget)
Widget primaryButtonUseCase(BuildContext context) {
  return FFButtonWidget(
    onPressed: () {},
    text: 'Primary Button',
    options: FFButtonOptions(
      height: 40,
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
      iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
      color: FlutterFlowTheme.of(context).primary,
      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
            fontFamily: 'Readex Pro',
            color: Colors.white,
          ),
      elevation: 3,
      borderSide: const BorderSide(
        color: Colors.transparent,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

@widgetbook.UseCase(name: 'Secondary Button', type: FFButtonWidget)
Widget secondaryButtonUseCase(BuildContext context) {
  return FFButtonWidget(
    onPressed: () {},
    text: 'Secondary Button',
    options: FFButtonOptions(
      height: 40,
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
      iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
      color: FlutterFlowTheme.of(context).secondary,
      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
            fontFamily: 'Readex Pro',
            color: Colors.white,
          ),
      elevation: 3,
      borderSide: const BorderSide(
        color: Colors.transparent,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
