import 'package:flutter/material.dart';
import '../../theme/yum_colors.dart';

enum YumButtonVariant { primary, dark, ghost }

class YumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final YumButtonVariant variant;
  final Widget? icon;
  final Color? bgColor;
  final Color? fgColor;

  const YumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.fullWidth = false,
    this.variant = YumButtonVariant.primary,
    this.icon,
    this.bgColor,
    this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    
    Color bgColor;
    Color fgColor;
    List<BoxShadow>? boxShadow;
    
    switch (variant) {
      case YumButtonVariant.primary:
        bgColor = colors.terracotta;
        fgColor = colors.paper;
        boxShadow = [
          BoxShadow(
            color: colors.terracotta.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ];
        break;
      case YumButtonVariant.dark:
        bgColor = colors.ink;
        fgColor = colors.paper;
        break;
      case YumButtonVariant.ghost:
        bgColor = colors.cream2;
        fgColor = colors.ink;
        break;
    }

    if (this.bgColor != null) bgColor = this.bgColor!;
    if (this.fgColor != null) fgColor = this.fgColor!;

    Widget content = Text(
      text,
      style: TextStyle(
        color: fgColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );

    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: fgColor, size: 16),
            child: icon!,
          ),
          const SizedBox(width: 8),
          content,
        ],
      );
    }

    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: boxShadow,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    } else {
      button = Row(mainAxisSize: MainAxisSize.min, children: [button]);
    }

    return Material(
      color: Colors.transparent,
      child: button,
    );
  }
}
