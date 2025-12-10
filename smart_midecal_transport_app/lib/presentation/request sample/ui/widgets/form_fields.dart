import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/common/custom_text_field.dart';
import '../cubit/request_blood_view_model.dart';

class FormFields {
  static Widget label(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static Widget inputField(
      TextEditingController controller, String hint, ThemeData theme) {
    return CustomTextField(
      controller: controller,
      label: hint,
      fillColor: theme.inputDecorationTheme.fillColor,
      borderColor: theme.highlightColor,
      borderWidth: 0.5,
      labelColor: theme.textTheme.bodySmall?.color,
    );
  }

  static Widget notesField(TextEditingController controller, ThemeData theme) {
    return CustomTextField(
      controller: controller,
      label: "Any additional information...",
      fillColor: theme.inputDecorationTheme.fillColor,
      borderColor: theme.highlightColor,
      labelColor: theme.textTheme.bodySmall?.color,
      maxLines: 5,
      borderWidth: 0.5,
    );
  }

  static Widget dropdown(RequestBloodViewModel vm, ThemeData theme, StateSetter setState) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12.r),
        border: BoxBorder.all(
          color: theme.highlightColor,
          width: 0.5,
        )
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.selectedBloodType,
          hint: Text("Select blood type",style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),),
          items: vm.bloodTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),)))
              .toList(),
          onChanged: (v) {
            setState(() => vm.selectedBloodType = v);
          },
        ),
      ),
    );
  }
}
