import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import '../domain/request_models.dart';

/// Car status widget showing load and dispatch button
class CarStatusWidget extends StatelessWidget {
  final TransportCar car;
  final VoidCallback? onDispatch;

  const CarStatusWidget({super.key, required this.car, this.onDispatch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillPercent = car.currentLoad / car.maxCapacity;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primaryDark.withValues(alpha: 0.2),
                  AppColors.secondary.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.primaryLight.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.3)
              : AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'requests.transport_car'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${car.currentLoad} / ${car.maxCapacity} ${'requests.loaded'.tr()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: car.isFull
                              ? AppColors.success
                              : AppColors.labelColor,
                          fontWeight: car.isFull
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!car.isEmpty)
                ElevatedButton.icon(
                  onPressed: onDispatch,
                  icon: Icon(Icons.send_rounded, size: 18.sp),
                  label: Text('requests.dispatch'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: car.isFull
                        ? AppColors.success
                        : AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          // Capacity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: fillPercent,
              minHeight: 8.h,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                car.isFull ? AppColors.success : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
