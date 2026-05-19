import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Shimmer animation mixin ──────────────────────────────────────────────

/// Animated shimmer placeholder box
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2B3A46) : const Color(0xFFE2E8F0);
    final highlight = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, highlight, _anim.value),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

// ─── Reusable skeleton components ────────────────────────────────────────

/// Skeleton placeholder for a single stats card
class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(
                width: 44.w,
                height: 44.w,
                borderRadius: BorderRadius.circular(12.r),
              ),
              const Spacer(),
              _ShimmerBox(
                width: 50.w,
                height: 20.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _ShimmerBox(width: 60.w, height: 22.h),
          SizedBox(height: 6.h),
          _ShimmerBox(width: 100.w, height: 14.h),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the filter bar
class FilterSkeleton extends StatelessWidget {
  const FilterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShimmerBox(
          width: 62.w,
          height: 34.h,
          borderRadius: BorderRadius.circular(24.r),
        ),
        SizedBox(width: 8.w),
        _ShimmerBox(
          width: 72.w,
          height: 34.h,
          borderRadius: BorderRadius.circular(24.r),
        ),
        SizedBox(width: 8.w),
        _ShimmerBox(
          width: 56.w,
          height: 34.h,
          borderRadius: BorderRadius.circular(24.r),
        ),
        SizedBox(width: 8.w),
        _ShimmerBox(
          width: 84.w,
          height: 34.h,
          borderRadius: BorderRadius.circular(24.r),
        ),
      ],
    );
  }
}

/// Skeleton placeholder for the donut chart section
class DonutChartSkeleton extends StatelessWidget {
  const DonutChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 140.w, height: 18.h),
              const Spacer(),
              _ShimmerBox(
                width: 70.w,
                height: 22.h,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circle donut placeholder
              _ShimmerBox(
                width: 130.w,
                height: 130.w,
                borderRadius: BorderRadius.circular(65.r),
              ),
              SizedBox(width: 20.w),
              // Legend placeholders
              Expanded(
                child: Column(
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: EdgeInsetsDirectional.only(bottom: 10.h),
                      child: const LegendSkeleton(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for a single legend item
class LegendSkeleton extends StatelessWidget {
  const LegendSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShimmerBox(
          width: 4.w,
          height: 32.h,
          borderRadius: BorderRadius.circular(4.r),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 80.w, height: 11.h),
              SizedBox(height: 4.h),
              _ShimmerBox(width: 40.w, height: 13.h),
            ],
          ),
        ),
        _ShimmerBox(
          width: 44.w,
          height: 22.h,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ],
    );
  }
}

// ─── Full-screen skeleton ─────────────────────────────────────────────────

/// Full skeleton screen that mirrors the real layout to avoid layout shift
class StatisticsSkeletonScreen extends StatelessWidget {
  const StatisticsSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Header
        _ShimmerBox(width: 180.w, height: 22.h),
        SizedBox(height: 6.h),
        _ShimmerBox(width: 120.w, height: 14.h),
        SizedBox(height: 6.h),
        _ShimmerBox(width: 90.w, height: 12.h),
        SizedBox(height: 20.h),

        // Filter bar
        const FilterSkeleton(),
        SizedBox(height: 24.h),

        // Section label
        _ShimmerBox(width: 160.w, height: 16.h),
        SizedBox(height: 14.h),

        // Stats cards grid — Doctor
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35,
          children: List.generate(4, (_) => const StatsCardSkeleton()),
        ),
        SizedBox(height: 24.h),

        // Donut chart placeholder — Doctor
        const DonutChartSkeleton(),
        SizedBox(height: 20.h),

        // Section label — Storage
        _ShimmerBox(width: 150.w, height: 16.h),
        SizedBox(height: 14.h),

        // Stats cards grid — Storage
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35,
          children: List.generate(4, (_) => const StatsCardSkeleton()),
        ),
        SizedBox(height: 24.h),

        // Donut chart placeholder — Storage
        const DonutChartSkeleton(),
        SizedBox(height: 32.h),
      ],
    );
  }
}
