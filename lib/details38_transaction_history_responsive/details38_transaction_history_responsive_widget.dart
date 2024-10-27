import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'details38_transaction_history_responsive_model.dart';
export 'details38_transaction_history_responsive_model.dart';

class Details38TransactionHistoryResponsiveWidget extends StatefulWidget {
  const Details38TransactionHistoryResponsiveWidget({super.key});

  @override
  State<Details38TransactionHistoryResponsiveWidget> createState() =>
      _Details38TransactionHistoryResponsiveWidgetState();
}

class _Details38TransactionHistoryResponsiveWidgetState
    extends State<Details38TransactionHistoryResponsiveWidget> {
  late Details38TransactionHistoryResponsiveModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(
        context, () => Details38TransactionHistoryResponsiveModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'Details38TransactionHistoryResponsive'});
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: MediaQuery.sizeOf(context).width <= 991.0
            ? AppBar(
                backgroundColor: Colors.white,
                automaticallyImplyLeading: false,
                leading: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 30.0,
                  borderWidth: 1.0,
                  buttonSize: 60.0,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF15161E),
                    size: 30.0,
                  ),
                  onPressed: () async {
                    logFirebaseEvent(
                        'DETAILS38_TRANSACTION_HISTORY_RESPONSIVE');
                    logFirebaseEvent('IconButton_navigate_back');
                    context.pop();
                  },
                ),
                title: Text(
                  FFLocalizations.of(context).getText(
                    'qo65x6ds' /* Order Details */,
                  ),
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFF15161E),
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        useGoogleFonts: GoogleFonts.asMap()
                            .containsKey('Plus Jakarta Sans'),
                      ),
                ),
                actions: [],
                centerTitle: false,
                elevation: 0.0,
              )
            : null,
      ),
    );
  }
}
