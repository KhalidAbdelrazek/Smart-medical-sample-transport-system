import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Shimmer-style loading skeleton — shown while the initial request is in flight.
class MyRequestsLoadingSkeleton extends StatefulWidget {
  const MyRequestsLoadingSkeleton({super.key});

  @override
  State<MyRequestsLoadingSkeleton> createState() =>
      _MyRequestsLoadingSkeletonState();
}

class _MyRequestsLoadingSkeletonState extends State<MyRequestsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => _SkeletonCard(opacity: _animation.value),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double opacity;
  const _SkeletonCard({required this.opacity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.cardDarkColor : AppColors.cardLightColor;
    final shimmer = isDark
        ? AppColors.cardDarkStrokeColor
        : AppColors.cardLightStrokeColor;

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status accent bar
            Container(
              width: 5.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  bottomLeft: Radius.circular(16.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _box(width: 90.w, height: 14.h, color: shimmer),
                        _box(
                          width: 70.w,
                          height: 22.h,
                          color: shimmer,
                          radius: 20.r,
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    _box(width: 140.w, height: 12.h, color: shimmer),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        _box(
                          width: 38.w,
                          height: 22.h,
                          color: shimmer,
                          radius: 8.r,
                        ),
                        SizedBox(width: 8.w),
                        _box(width: 70.w, height: 12.h, color: shimmer),
                        SizedBox(width: 8.w),
                        _box(width: 80.w, height: 12.h, color: shimmer),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({
    required double width,
    required double height,
    required Color color,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
