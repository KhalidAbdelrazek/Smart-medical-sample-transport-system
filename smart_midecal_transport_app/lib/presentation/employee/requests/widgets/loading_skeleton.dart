import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Skeleton loading widget for requests tab
class RequestLoadingSkeleton extends StatelessWidget {
  const RequestLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        // Form skeleton
        _shimmerBox(double.infinity, 320.h, isDark),
        SizedBox(height: 25.h),
        // Recent requests header skeleton
        _shimmerBox(180.w, 20.h, isDark),
        SizedBox(height: 12.h),
        // Request cards skeleton
        _shimmerBox(double.infinity, 90.h, isDark),
        SizedBox(height: 12.h),
        _shimmerBox(double.infinity, 90.h, isDark),
        SizedBox(height: 12.h),
        _shimmerBox(double.infinity, 90.h, isDark),
      ],
    );
  }

  Widget _shimmerBox(double width, double height, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.6),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.grey).withValues(
              alpha: value,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
        );
      },
    );
  }
}
