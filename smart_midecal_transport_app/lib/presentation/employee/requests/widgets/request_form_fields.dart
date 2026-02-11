import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Reusable form field helpers for request forms
class RequestFormFields {
  /// Form label text
  static Widget label(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Text input field
  static Widget inputField({
    required TextEditingController controller,
    required String hint,
    required ThemeData theme,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.labelColor,
        ),
        filled: true,
        fillColor:
            theme.inputDecorationTheme.fillColor ??
            theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: theme.primaryColor, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  /// Blood type dropdown
  static Widget dropdown({
    required String? selectedValue,
    required List<String> items,
    required String hint,
    required ThemeData theme,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color:
            theme.inputDecorationTheme.fillColor ??
            theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          hint: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.labelColor,
            ),
          ),
          items: items
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: theme.textTheme.bodyLarge),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Urgency level selector buttons
  static Widget urgencySelector({
    required String selected,
    required List<Map<String, String>> options,
    required ThemeData theme,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = AppColors.buttonColor;
    final inactiveColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Row(
      children: options.map((option) {
        final isSelected = selected == option['value'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option != options.last ? 12.w : 0),
            child: GestureDetector(
              onTap: () => onChanged(option['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  option['label']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
