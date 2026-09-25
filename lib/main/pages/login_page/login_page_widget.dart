import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => LoginPageWidgetState();
}

class LoginPageWidgetState extends State<LoginPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _account.text.trim(),
        password: _password.text,
      );
      if (mounted) context.go(YbRoute.home.routeName);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = switch (error.code) {
              'network-request-failed' => '無法連線，請檢查網路後重試',
              'too-many-requests' => '嘗試次數過多，請稍後再試',
              _ => '登入失敗，請確認帳號與密碼',
            });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '登入失敗，請稍後重試');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
            image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/images/login_bg.webp'),
        )),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, viewport) {
            final wide = viewport.maxWidth >= 700;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight:
                        (viewport.maxHeight - 48).clamp(0, double.infinity)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Row(children: [
                      if (wide)
                        const Expanded(
                            flex: 4,
                            child: Padding(
                              padding: EdgeInsets.only(right: 24),
                              child: Image(
                                  image: AssetImage(
                                      'assets/images/login_avatar.webp')),
                            )),
                      Expanded(
                          flex: 6,
                          child: Container(
                            padding: EdgeInsets.all(wide ? 40 : 24),
                            decoration: BoxDecoration(
                                color: theme.tertiary.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(32)),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text('黃絲帶愛網關懷協會',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: theme.primaryText)),
                                    const SizedBox(height: 32),
                                    TextFormField(
                                      controller: _account,
                                      enabled: !_submitting,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username
                                      ],
                                      decoration: const InputDecoration(
                                          labelText: '帳號',
                                          hintText: 'Email',
                                          border: OutlineInputBorder()),
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        if (email.isEmpty) return '請輸入帳號';
                                        if (!RegExp(
                                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(email))
                                          return '請輸入有效的 Email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _password,
                                      enabled: !_submitting,
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password
                                      ],
                                      decoration: const InputDecoration(
                                          labelText: '密碼',
                                          border: OutlineInputBorder()),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? '請輸入密碼'
                                              : null,
                                      onFieldSubmitted: (_) => _login(),
                                    ),
                                    if (_error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Semantics(
                                            liveRegion: true,
                                            child: Text(_error!,
                                                style: TextStyle(
                                                    color: theme.error))),
                                      ),
                                    const SizedBox(height: 28),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(48),
                                          backgroundColor: theme.primary,
                                          foregroundColor: Colors.white),
                                      onPressed: _submitting ? null : _login,
                                      child: _submitting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : const Text('登入',
                                              style: TextStyle(fontSize: 18)),
                                    ),
                                  ]),
                            ),
                          )),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
