import 'package:flutter/material.dart';

enum ButtonType {
  primary(Color(0xFF194680), Colors.white),
  secondary(Colors.transparent, Color(0xFF194680), Color(0xFF194680)),
  ghost(Colors.transparent, Color(0xFF194680)),
  filledTonal(Color(0xFF57C8E7), Colors.white),
  cta(Color(0xFFFFE13A), Color(0xFF194680)),
  error(Colors.transparent, Color(0xFFFF4040), Color(0xFFFF4040));

  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const ButtonType(this.backgroundColor, this.textColor, [this.borderColor]);
}

enum ButtonSize {
  large(42, 20, 16),
  medium(34, 20, 14),
  small(26, 12, 14);

  final double height;
  final double horizontalPadding;
  final double fontSize;

  const ButtonSize(this.height, this.horizontalPadding, this.fontSize);
}

enum ButtonState {
  enabled,
  loading,
  pressed,
  disabled,
}

class YbButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;

  const YbButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<YbButton> createState() => _YbButtonState();
}

class _YbButtonState extends State<YbButton> {
  bool _isPressed = false;

  ButtonState get _currentState {
    if (widget.isDisabled) return ButtonState.disabled;
    if (widget.isLoading) return ButtonState.loading;
    if (_isPressed) return ButtonState.pressed;
    return ButtonState.enabled;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled && !widget.isLoading && widget.onPressed != null) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (_isPressed) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        }
      },
      onTapCancel: () {
        if (_isPressed) {
          setState(() => _isPressed = false);
        }
      },
      child: Opacity(
        opacity: widget.isDisabled ? 0.25 : 1.0,
        child: Container(
          height: widget.size.height,
          padding: EdgeInsets.symmetric(horizontal: widget.size.horizontalPadding, vertical: 4),
          decoration: BoxDecoration(
            color: _currentState == ButtonState.pressed
                ? widget.type.backgroundColor.withOpacity(0.8)
                : widget.type.backgroundColor,
            borderRadius: BorderRadius.circular(9999),
            border: widget.type.borderColor != null
                ? Border.all(color: widget.type.borderColor!, width: 1)
                : null,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return _buildLoadingIndicator();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 4),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: widget.type.textColor,
            fontSize: widget.size.fontSize,
            fontWeight: widget.type == ButtonType.ghost ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LoadingDots(color: widget.type.textColor),
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
  final Color color;

  const _LoadingDots({required this.color});

  @override
  _LoadingDotsState createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index / 3;
            final value = (((_controller.value + delay) % 1.0) < 0.5)
                ? ((_controller.value + delay) % 0.5) * 2
                : 1 - (((_controller.value + delay) % 0.5) * 2);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 8 * (0.5 + value / 2),
              width: 8 * (0.5 + value / 2),
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
