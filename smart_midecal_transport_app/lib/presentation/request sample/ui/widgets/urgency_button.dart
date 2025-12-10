import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import '../cubit/request_blood_view_model.dart';

class UrgencyButtons extends StatelessWidget {
  final RequestBloodViewModel requestBloodViewModel;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onChange;

  const UrgencyButtons({
    super.key,
    required this.requestBloodViewModel,
    required this.theme,
    required this.isDark,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    Color active = AppColors.buttonColor;
    Color inactive = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    Widget btn(String text, String value) {
      bool selected = requestBloodViewModel.urgency == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            requestBloodViewModel.urgency = value;
            onChange();
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? active : inactive,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn("Normal", "normal"),
        SizedBox(width: 12.w),
        btn("Urgent", "urgent"),
        SizedBox(width: 12.w),
        btn("Critical", "critical"),
      ],
    );
  }
}
