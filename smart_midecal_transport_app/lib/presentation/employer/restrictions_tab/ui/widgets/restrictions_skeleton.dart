import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class RestrictionsSkeleton extends StatelessWidget {
  const RestrictionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        _shimmerHeader(cs),
        SizedBox(height: 32.h),
        _buildSkeletonCard(cs, hasSubContent: true),
        SizedBox(height: 16.h),
        _buildSkeletonCard(cs, hasSubContent: true),
        SizedBox(height: 16.h),
        _buildSkeletonCard(cs, hasSubContent: false),
      ],
    );
  }

  Widget _shimmerHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerBox(180.w, 24.h, cs),
        SizedBox(height: 8.h),
        _shimmerBox(240.w, 14.h, cs),
      ],
    );
  }

  Widget _buildSkeletonCard(ColorScheme cs, {required bool hasSubContent}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _shimmerBox(40.w, 40.w, cs, radius: 10),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(120.w, 16.h, cs),
                    SizedBox(height: 6.h),
                    _shimmerBox(180.w, 12.h, cs),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _shimmerBox(40.w, 24.h, cs, radius: 12),
              if (hasSubContent) ...[
                SizedBox(width: 8.w),
                _shimmerBox(20.w, 20.w, cs, radius: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, ColorScheme cs,
      {double radius = 4}) {
    return Shimmer.fromColors(
      baseColor: cs.outlineVariant.withOpacity(0.4),
      highlightColor: cs.outlineVariant.withOpacity(0.1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
