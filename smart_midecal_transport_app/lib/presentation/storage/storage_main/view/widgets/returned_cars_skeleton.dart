import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class _PulseBar extends StatefulWidget {
  const _PulseBar({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ).value;
        final base = Color.lerp(
          scheme.surfaceContainerHighest,
          scheme.surfaceContainerHigh,
          t,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
          ),
        );
      },
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PulseBar(
                  width: 44.w,
                  height: 44.w,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PulseBar(
                        width: double.infinity,
                        height: 18.h,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      SizedBox(height: 8.h),
                      _PulseBar(
                        width: 120.w,
                        height: 14.h,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _PulseBar(
              width: double.infinity,
              height: 40.h,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer-style placeholders for the returned cars list.
class ReturnedCarsSkeleton extends StatelessWidget {
  const ReturnedCarsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => const _CardSkeleton(),
    );
  }
}
