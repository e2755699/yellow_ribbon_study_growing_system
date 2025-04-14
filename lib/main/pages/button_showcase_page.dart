import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/yb_button.dart';

class ButtonShowcasePage extends StatefulWidget {
  const ButtonShowcasePage({Key? key}) : super(key: key);

  @override
  State<ButtonShowcasePage> createState() => _ButtonShowcasePageState();
}

class _ButtonShowcasePageState extends State<ButtonShowcasePage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('按鈕展示'),
        actions: [
          Switch(
            value: _isLoading,
            onChanged: (value) {
              setState(() {
                _isLoading = value;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(child: Text('加載狀態')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('主要按鈕 (Primary)', ButtonType.primary),
            _buildSection('次要按鈕 (Secondary)', ButtonType.secondary),
            _buildSection('幽靈按鈕 (Ghost)', ButtonType.ghost),
            _buildSection('填充色調按鈕 (Filled Tonal)', ButtonType.filledTonal),
            _buildSection('行動號召按鈕 (CTA)', ButtonType.cta),
            _buildSection('錯誤按鈕 (Error)', ButtonType.error),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, ButtonType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildButtonVariant(
              '大尺寸',
              type,
              ButtonSize.large,
              isLoading: _isLoading,
            ),
            _buildButtonVariant(
              '中尺寸',
              type,
              ButtonSize.medium,
              isLoading: _isLoading,
            ),
            _buildButtonVariant(
              '小尺寸',
              type,
              ButtonSize.small,
              isLoading: _isLoading,
            ),
            _buildButtonVariant(
              '禁用',
              type,
              ButtonSize.medium,
              isDisabled: true,
            ),
            _buildButtonVariant(
              '帶圖標',
              type,
              ButtonSize.medium,
              icon: Icon(
                Icons.add,
                size: 20,
                color: type.textColor,
              ),
            ),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildButtonVariant(
    String label,
    ButtonType type,
    ButtonSize size, {
    bool isLoading = false,
    bool isDisabled = false,
    Widget? icon,
  }) {
    return Column(
      children: [
        YbButton(
          text: label,
          onPressed: isDisabled ? null : () {},
          type: type,
          size: size,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
} 