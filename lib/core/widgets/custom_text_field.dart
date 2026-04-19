import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final String? helperText;
  final String? errorText;
  final int? maxLines;
  final bool enabled;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.helperText,
    this.errorText,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.captionBold,
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          enabled: widget.enabled,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textLight),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.textLight)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.backgroundWhite
                : AppColors.backgroundGray,
            helperText: widget.helperText,
            helperStyle: AppTextStyles.small,
            errorText: widget.errorText,
            errorStyle: AppTextStyles.small.copyWith(color: AppColors.occupiedRed),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.disabledGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.disabledGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.occupiedRed),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
          ),
        ),
      ],
    );
  }
}
