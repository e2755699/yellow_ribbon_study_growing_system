import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView(
      {super.key, required this.onLogin, required this.onDemo});
  final Future<String?> Function(String email, String password) onLogin;
  final VoidCallback onDemo;
  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false, _obscure = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = await widget.onLogin(_email.text.trim(), _password.text);
      if (mounted) {
        setState(() {
          _error = error;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '登入失敗，請稍後重試。';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context),
        gap = SystemTheme.of(context).metric('spaceMedium');
    return Scaffold(
        backgroundColor: ds.color('secondary'),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: EdgeInsets.all(ds.metric('spaceLarge')),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Container(
                            padding: EdgeInsets.all(ds.metric('spaceLarge')),
                            decoration: ds.cardDecoration,
                            child: Form(
                                key: _form,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                  color: ds.surfaceTone(100),
                                                  borderRadius: ds.cardRadius),
                                              child: Icon(Icons.spa_outlined,
                                                  color: ds.brandTone(700),
                                                  size: 30))),
                                      SizedBox(height: gap),
                                      Text('黃絲帶管理後台',
                                          style: TextStyle(
                                              fontSize:
                                                  ds.metric('headingSize'),
                                              fontWeight: FontWeight.w700,
                                              color: ds.color('primaryText'))),
                                      SizedBox(height: gap / 2),
                                      Text('月出席報表，一處查看與下載。',
                                          style: TextStyle(
                                              fontSize: ds.metric('bodySize'),
                                              color:
                                                  ds.color('secondaryText'))),
                                      SizedBox(height: gap * 2),
                                      TextFormField(
                                          controller: _email,
                                          enabled: !_busy,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.username
                                          ],
                                          decoration: const InputDecoration(
                                              labelText: '帳號 Email',
                                              prefixIcon:
                                                  Icon(Icons.mail_outline)),
                                          validator: (value) => value == null ||
                                                  !value.contains('@')
                                              ? '請輸入有效的 Email'
                                              : null),
                                      SizedBox(height: gap),
                                      TextFormField(
                                          controller: _password,
                                          enabled: !_busy,
                                          obscureText: _obscure,
                                          autofillHints: const [
                                            AutofillHints.password
                                          ],
                                          onFieldSubmitted: (_) => _submit(),
                                          decoration: InputDecoration(
                                              labelText: '密碼',
                                              prefixIcon: const Icon(
                                                  Icons.lock_outline),
                                              suffixIcon: IconButton(
                                                  tooltip: _obscure
                                                      ? '顯示密碼'
                                                      : '隱藏密碼',
                                                  onPressed: () => setState(
                                                      () =>
                                                          _obscure = !_obscure),
                                                  icon: Icon(_obscure
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined))),
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                                  ? '請輸入密碼'
                                                  : null),
                                      if (_error != null) ...[
                                        SizedBox(height: gap),
                                        Text(_error!,
                                            style: TextStyle(
                                                color: ds.color('error'),
                                                fontSize:
                                                    ds.metric('bodySize')))
                                      ],
                                      SizedBox(height: gap * 1.5),
                                      ElevatedButton.icon(
                                          onPressed: _busy ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                              textStyle: TextStyle(
                                                  fontSize:
                                                      ds.metric('bodySize'),
                                                  fontWeight: FontWeight.w700)),
                                          icon: _busy
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : const Icon(Icons.login),
                                          label: Text(_busy ? '登入中…' : '登入後台')),
                                      SizedBox(height: gap / 2),
                                      OutlinedButton(
                                          onPressed:
                                              _busy ? null : widget.onDemo,
                                          style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(44)),
                                          child: const Text('先看示範報表')),
                                      SizedBox(height: gap),
                                      Text('使用目前 App 的帳號登入；可查看的據點依既有授權。',
                                          style: TextStyle(
                                              fontSize: ds.metric('labelSize'),
                                              color: ds.color('secondaryText'),
                                              height: 1.6)),
                                    ]))))))));
  }
}
