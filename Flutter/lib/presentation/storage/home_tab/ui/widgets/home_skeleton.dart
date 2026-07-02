import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Shimmer box ──────────────────────────────────────────────────────────

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

// ─── Card skeleton ────────────────────────────────────────────────────────

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

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

// ─── Full skeleton ────────────────────────────────────────────────────────

/// Full skeleton screen for Storage Home Dashboard.
class StorageHomeSkeleton extends StatelessWidget {
  const StorageHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Welcome header skeleton
        _ShimmerBox(
          width: double.infinity,
          height: 110.h,
          borderRadius: BorderRadius.circular(20.r),
        ),
        SizedBox(height: 24.h),

        // Section label
        _ShimmerBox(width: 160.w, height: 16.h),
        SizedBox(height: 14.h),

        // Donut chart placeholder
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: _ShimmerBox(
              width: 150.w,
              height: 150.w,
              borderRadius: BorderRadius.circular(75.r),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Stats grid
        _ShimmerBox(width: 140.w, height: 16.h),
        SizedBox(height: 14.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35,
          children: List.generate(4, (_) => const _CardSkeleton()),
        ),
        SizedBox(height: 12.h),
        // last row (2 wide cards)
        Row(
          children: [
            Expanded(child: _CardSkeleton()),
            SizedBox(width: 12.w),
            Expanded(child: _CardSkeleton()),
          ],
        ),
        SizedBox(height: 32.h),
      ],
    );
  }
}
