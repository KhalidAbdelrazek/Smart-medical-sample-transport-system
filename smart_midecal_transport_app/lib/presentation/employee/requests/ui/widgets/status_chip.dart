import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Small UI chip component to indicate 'REQUESTED', 'IN_STORAGE', etc.
class StatusChip extends StatelessWidget {
  final String status;
  
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Map status strings to explicit colors
    final color = switch (status) {
      'IN_STORAGE' => AppColors.info,
      'REQUESTED' => AppColors.warning,
      'OUT_FOR_DELIVERY' => AppColors.success,
      _ => Colors.grey,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

