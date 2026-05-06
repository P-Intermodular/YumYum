import 'package:flutter/material.dart';
import '../../theme/yum_colors.dart';

class YumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const YumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
    
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
      content = Material(
        color: Colors.transparent,
        child: content,
      );
    }

    return content;
  }
}
