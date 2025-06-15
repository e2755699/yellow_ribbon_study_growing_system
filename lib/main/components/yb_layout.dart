import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/single_child_widget.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class YbLayout extends StatelessWidget {
  final Widget child;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final List<SingleChildWidget>? providers;
  /// 離開頁面前的回調函數，用於保存資料
  final Future<bool> Function()? onBeforeExit;
  /// 是否顯示保存確認對話框
  final bool showSaveConfirmation;

  const YbLayout({
    super.key,
    required this.scaffoldKey,
    required this.child,
    required this.title,
    this.providers,
    this.onBeforeExit,
    this.showSaveConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    return _layout(context);
  }

  Widget _layout(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
            color: FlutterFlowTheme.of(context).primaryText,
            onPressed: () => _handleBackButton(context),
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
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage("assets/images/login_bg.webp"),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(FlutterFlowTheme.of(context).spaceLarge),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 處理返回按鈕邏輯
  Future<void> _handleBackButton(BuildContext context) async {
    if (onBeforeExit != null) {
      if (showSaveConfirmation) {
        // 顯示保存確認對話框
        final shouldSave = await _showSaveConfirmationDialog(context);
        if (shouldSave == null) return; // 使用者取消操作
        
        if (shouldSave) {
          // 執行保存邏輯
          try {
            final saveSuccess = await onBeforeExit!();
            if (saveSuccess) {
              _showSuccessSnackBar(context);
            } else {
              _showErrorSnackBar(context);
              return; // 保存失敗，不離開頁面
            }
          } catch (e) {
            _showErrorSnackBar(context);
            return; // 保存過程出錯，不離開頁面
          }
        }
      } else {
        // 直接執行保存邏輯，不顯示對話框
        try {
          await onBeforeExit!();
        } catch (e) {
          _showErrorSnackBar(context);
          return;
        }
      }
    }
    
    // 離開頁面
    context.pop();
  }

  /// 顯示保存確認對話框
  Future<bool?> _showSaveConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '保存變更',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '您是否要保存目前的變更？',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // 取消
              child: Text(
                '取消',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // 不保存
              child: Text(
                '不保存',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).error,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // 保存
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  /// 顯示成功提示
  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('資料已成功保存'),
        backgroundColor: FlutterFlowTheme.of(context).success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 顯示錯誤提示
  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('保存失敗，請重試'),
        backgroundColor: FlutterFlowTheme.of(context).error,
        duration: const Duration(seconds: 3),
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
