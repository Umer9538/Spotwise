import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(AppSizes.md),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: card,
      );
    }

    return card;
  }
}
