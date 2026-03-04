import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Skeleton loading widget for requests tab
class RequestLoadingSkeleton extends StatelessWidget {
  const RequestLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search section skeleton
          _shimmerBox(150.w, 20.h, isDark),
          SizedBox(height: 12.h),
          _shimmerBox(double.infinity, 56.h, isDark),
          SizedBox(height: 24.h),
          // Details card skeleton
          _shimmerBox(double.infinity, 400.h, isDark),
        ],
      ),
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
