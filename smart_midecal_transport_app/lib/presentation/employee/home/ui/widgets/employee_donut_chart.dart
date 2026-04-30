import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:donut_chart/donut_chart.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

class EmployeeDonutChart extends StatefulWidget {
  final int pending;
  final int cancelled;
  final int failed;
  final int success;

  const EmployeeDonutChart({
    super.key,
    required this.pending,
    required this.cancelled,
    required this.failed,
    required this.success,
  });

  @override
  State<EmployeeDonutChart> createState() => _EmployeeDonutChartState();
}

class _EmployeeDonutChartState extends State<EmployeeDonutChart> {
  String? selectedLabel;
  double? selectedValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = widget.pending +
        widget.cancelled +
        widget.failed +
        widget.success;

    /// ✅ Handle ZERO DATA
    if (total == 0) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: _decoration(theme),
        child: Center(
          child: Text(
            "No data available",
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: _decoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Requests Distribution",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20.h),

          /// ✅ CHART + CENTER LEGEND
          Stack(
            alignment: Alignment.center,
            children: [
              DonutChartWidget(
                size: 220,
                strokeWidth: 28,
                tooltipBgColor: Colors.grey.withValues(alpha: 0.8),
                data: [
                  DonutSectionModel(
                    label: "Pending",
                    value: widget.pending.toDouble(),
                    color: AppColors.warning,
                  ),
                  DonutSectionModel(
                    label: "Cancelled",
                    value: widget.cancelled.toDouble(),
                    color: AppColors.error,
                  ),
                  DonutSectionModel(
                    label: "Failed",
                    value: widget.failed.toDouble(),
                    color: Colors.black,
                  ),
                  DonutSectionModel(
                    label: "Success",
                    value: widget.success.toDouble(),
                    color: AppColors.success,
                  ),
                ],
              ),

              /// ✅ CENTER LEGEND / SELECTED DATA
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedLabel ?? "Total",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    selectedValue != null
                        ? selectedValue!.toInt().toString()
                        : total.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20.h),

          /// ✅ LEGEND LIST (MATCH COLORS)
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              _legendItem("Pending", widget.pending, AppColors.warning),
              _legendItem("Cancelled", widget.cancelled, AppColors.error),
              _legendItem("Failed", widget.failed, Colors.black),
              _legendItem("Success", widget.success, AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ CARD DECORATION (reuse)
  BoxDecoration _decoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// ✅ LEGEND ITEM
  Widget _legendItem(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            "$label ($value)",
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}