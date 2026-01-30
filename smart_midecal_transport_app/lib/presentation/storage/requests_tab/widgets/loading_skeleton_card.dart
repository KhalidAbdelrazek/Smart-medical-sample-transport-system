import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading skeleton card
class LoadingSkeletonCard extends StatefulWidget {
  const LoadingSkeletonCard({super.key});

  @override
  State<LoadingSkeletonCard> createState() => _LoadingSkeletonCardState();
}

class _LoadingSkeletonCardState extends State<LoadingSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(80.w, 20.h, isDark, _animation.value),
                  _shimmerBox(60.w, 24.h, isDark, _animation.value),
                ],
              ),
              SizedBox(height: 16.h),
              _shimmerBox(double.infinity, 16.h, isDark, _animation.value),
              SizedBox(height: 10.h),
              _shimmerBox(150.w, 16.h, isDark, _animation.value),
              SizedBox(height: 16.h),
              _shimmerBox(double.infinity, 40.h, isDark, _animation.value),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, bool isDark, double opacity) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.grey).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
