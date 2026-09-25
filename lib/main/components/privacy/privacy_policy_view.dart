import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_page.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/model/privacy_policy.dart';

/// Fully bundled text: no network, account or backend is needed to read it.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView(
      {super.key,
      required this.updated,
      required this.sections,
      required this.onBack,
      required this.scaffoldKey});
  final String updated;
  final List<PrivacyPolicySection> sections;
  final VoidCallback onBack;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return SystemPage(
        title: '隱私權政策',
        scaffoldKey: scaffoldKey,
        showSaveConfirmation: false,
        onBack: onBack,
        child: Align(
            alignment: Alignment.topCenter,
            // Structural reading width, shared typography still follows the theme.
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: SingleChildScrollView(
                    key: const Key('privacy-policy-scroll'),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(bottom: gap),
                              child: Text('更新日期：$updated',
                                  style: TextStyle(
                                      fontSize: ds.metric('bodySize'),
                                      color: ds.color('primaryText')))),
                          for (final section in sections)
                            Padding(
                                padding: EdgeInsets.only(bottom: gap),
                                child: SystemSectionCard(
                                    title: section.title,
                                    icon: Icons.privacy_tip_outlined,
                                    child: SelectableText(section.body,
                                        style: TextStyle(
                                            fontSize: ds.metric('bodySize'),
                                            height: 1.7,
                                            color: ds.color('primaryText'))))),
                        ])))));
  }
}

class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return Material(
        color: ds.color('secondaryBackground'),
        borderRadius: ds.cardRadius,
        child: TextButton.icon(
            onPressed: onPressed,
            style: TextButton.styleFrom(
                foregroundColor: ds.color('primaryText'),
                disabledForegroundColor:
                    ds.color('secondaryText').withOpacity(.5),
                minimumSize: const Size(44, 44),
                padding:
                    EdgeInsets.symmetric(horizontal: ds.metric('spaceMedium')),
                textStyle: TextStyle(fontSize: ds.metric('labelSize')),
                shape: RoundedRectangleBorder(borderRadius: ds.cardRadius)),
            icon: const Icon(Icons.privacy_tip_outlined, size: 20),
            label: const Text('隱私權政策')));
  }
}
