import 'package:flutter/material.dart';
import '../../design_system/presentation/system_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/single_child_widget.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class YbLayout extends StatefulWidget {
  final Widget child;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final List<SingleChildWidget>? providers;
  final Future<bool> Function()? onBeforeExit;
  final bool showSaveConfirmation;
  final Decoration? backgroundDecoration;
  final Color? headerColor;
  final Color? foregroundColor;
  final bool circularBackButton;
  final VoidCallback? onBack;

  const YbLayout(
      {super.key,
      required this.scaffoldKey,
      required this.child,
      required this.title,
      this.providers,
      this.onBeforeExit,
      this.backgroundDecoration,
      this.headerColor,
      this.foregroundColor,
      this.circularBackButton = false,
      this.onBack,
      this.showSaveConfirmation = true});

  @override
  State<YbLayout> createState() => _YbLayoutState();
}

class _YbLayoutState extends State<YbLayout> {
  bool _leaving = false;
  bool _allowPop = false;

  Future<void> _requestExit() async {
    if (_leaving) return;
    _leaving = true;
    try {
      var shouldSave = true;
      if (widget.onBeforeExit != null && widget.showSaveConfirmation) {
        // 三個選項層級：取消（文字）< 不保存（外框）< 保存（主按鈕）；
        // 對話框內一律用正文字級，避免主按鈕的大字把其他選項壓成附註。
        final ds = SystemTheme.of(context);
        final actionText = TextStyle(
            fontSize: ds.metric('bodySize'), fontWeight: FontWeight.w700);
        const actionSize = Size(88, 44);
        final choice = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                  title: const Text('保存變更'),
                  content: const Text('您是否要保存目前的變更？'),
                  actionsPadding: EdgeInsets.fromLTRB(ds.metric('spaceMedium'),
                      0, ds.metric('spaceMedium'), ds.metric('spaceMedium')),
                  actions: [
                    TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: actionSize, textStyle: actionText),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('取消')),
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: actionSize, textStyle: actionText),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('不保存')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: actionSize,
                            textStyle: actionText,
                            padding: EdgeInsets.symmetric(
                                horizontal: ds.metric('spaceMedium'))),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('保存')),
                  ],
                ));
        if (choice == null || !mounted) return;
        shouldSave = choice;
      }
      if (shouldSave && widget.onBeforeExit != null) {
        final saved = await widget.onBeforeExit!();
        if (!mounted) return;
        if (!saved) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('尚未儲存，請檢查表單或等待操作完成')));
          return;
        }
      }
      if (!mounted) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (widget.onBack != null) {
        widget.onBack!();
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失敗，請重試')));
    } finally {
      _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return PopScope(
      canPop: widget.onBeforeExit == null || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        key: widget.scaffoldKey,
        appBar: AppBar(
          toolbarHeight: 64,
          leading: Padding(
            padding: EdgeInsets.all(widget.circularBackButton ? 6 : 0),
            child: Material(
                color: widget.circularBackButton
                    ? Colors.white
                    : Colors.transparent,
                shape: const CircleBorder(),
                child: IconButton(
                    tooltip: '返回',
                    onPressed: _requestExit,
                    style: widget.circularBackButton
                        ? IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: widget.foregroundColor)
                        : null,
                    icon: Icon(widget.circularBackButton
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_back_ios_new))),
          ),
          centerTitle: true,
          title: Text(widget.title,
              style: Theme.of(context).extension<SystemTheme>() != null
                  ? Theme.of(context).textTheme.titleLarge
                  : const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          backgroundColor: widget.headerColor ?? theme.primaryBackground,
          foregroundColor: widget.foregroundColor ?? theme.primaryText,
          elevation: widget.circularBackButton ? 1 : null,
        ),
        backgroundColor: theme.secondary,
        body: DecoratedBox(
          decoration: widget.backgroundDecoration ??
              const BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/images/login_bg.webp'))),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
                builder: (context, constraints) => Padding(
                      padding:
                          EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 24),
                      child: widget.child,
                    )),
          ),
        ),
      ),
    );
  }
}
