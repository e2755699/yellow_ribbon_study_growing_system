import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class YbLayout extends StatelessWidget {
  final Widget child;
  final GlobalKey<ScaffoldState> scaffoldKey;

  final String title;

  const YbLayout({super.key, required this.scaffoldKey, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return _layout(context);
  }

  Scaffold _layout(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
            color: FlutterFlowTheme.of(context).primaryText,
            onPressed: () {
              //todo 離開要save
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new)),
        backgroundColor: Colors.transparent, // 設置透明背景
        elevation: 0, // 去除陰影
        title: Center(
          child: _text(title,
              color: FlutterFlowTheme.of(context).primaryText, size: 32),
        ),
      ),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
      body: SafeArea(
        top: true,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fitWidth,
              image: AssetImage("assets/images/login_bg.webp"),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Text _text(String data, {Color? color, double? size}) {
    return Text(
      data,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
