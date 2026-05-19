import 'package:donut_chart/donut_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/ui/cubit/statistics_state.dart';
import 'legend_item.dart';

// Chart palette — distinct, visually appealing colors
const List<Color> _chartPalette = [
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // emerald
  Color(0xFFF59E0B), // amber
  Color(0xFFEF4444), // red
  Color(0xFF8B5CF6), // violet
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
];

/// Power BI-style donut chart with animated switcher and legend
class DonutChartSection extends StatelessWidget {
  final String title;
  final List<ChartSegment> segments;
  final int total;
  final String centerLabel;

  const DonutChartSection({
    super.key,
    required this.title,
    required this.segments,
    required this.total,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${"employee.total".tr()} : $total',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          if (segments.isEmpty)
            _EmptyChart(theme: theme)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut chart
                SizedBox(
                  width: 130.w,
                  height: 130.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DonutChartWidget(
                        data: segments
                            .asMap()
                            .entries
                            .map(
                              (e) => DonutSectionModel(
                                label: e.value.labelKey.tr(),
                                color:
                                    _chartPalette[e.key % _chartPalette.length],
                                value: e.value.value.toDouble(),
                              ),
                            )
                            .toList(),
                        size: 130.w,
                        strokeWidth: 22,
                      ),
                      // Center label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20.sp,
                            ),
                          ),
                          Text(
                            centerLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),

                // Legend
                Expanded(
                  child: Column(
                    children: segments.asMap().entries.map((e) {
                      final color = _chartPalette[e.key % _chartPalette.length];
                      return LegendItem(
                        color: color,
                        label: e.value.labelKey.tr(),
                        percentage: e.value.percentage,
                        value: e.value.value,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final ThemeData theme;
  const _EmptyChart({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48.sp,
              color: theme.dividerColor,
            ),
            SizedBox(height: 8.h),
            Text('extra.no_data_period'.tr(), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}