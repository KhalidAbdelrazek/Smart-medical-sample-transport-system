import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final Color? borderColor;
  final Color? inputColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final Color? fillColor;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final String? Function(String?)? validator;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final double? borderWidth;

  const CustomTextField({
    super.key,
    required this.label,
    this.labelColor,
    this.borderColor,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.validator,
    this.enabled = true,
    this.maxLines,
    this.inputColor,
    this.prefixIconColor,
    this.maxLength,
    this.suffixIconColor,
    this.fillColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      enabled: enabled,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: inputColor ?? (isDark ? Colors.white : AppColors.textColor),
      ),
      cursorColor: theme.primaryColor,
      decoration: InputDecoration(
        fillColor: fillColor ?? theme.inputDecorationTheme.fillColor,
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        labelText: label, // Using labelText for modern floating behavior
        alignLabelWithHint: maxLines != null && maxLines! > 1,
        labelStyle: TextStyle(
          color: labelColor ?? AppColors.labelColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
        ),
        floatingLabelStyle: TextStyle(
          color: theme.primaryColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: (labelColor ?? AppColors.labelColor).withOpacity(0.5),
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon, 
                color: prefixIconColor ?? theme.iconTheme.color?.withOpacity(0.7),
                size: 20.sp,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: suffixIconColor ?? theme.primaryColor,
                  size: 20.sp,
                ),
                onPressed: onSuffixPressed,
              )
            : null,
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        focusedBorder: theme.inputDecorationTheme.focusedBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
