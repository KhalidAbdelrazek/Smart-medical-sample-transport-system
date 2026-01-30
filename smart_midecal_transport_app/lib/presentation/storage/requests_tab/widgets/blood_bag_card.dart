import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import '../domain/request_models.dart';

/// Card for blood bag request (pending or added to car)
class BloodBagCard extends StatelessWidget {
  final BloodBagRequest request;
  final bool isInCar;
  final VoidCallback? onAction;
  final int index;

  const BloodBagCard({
    super.key,
    required this.request,
    required this.isInCar,
    this.onAction,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isInCar
                ? AppColors.success.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _getBloodTypeColor(
                  request.bloodType,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getBloodTypeColor(request.bloodType),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      request.bloodType.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      request.id,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isInCar)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'requests.in_car'.tr(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _infoRow(
                    context,
                    Icons.bloodtype_rounded,
                    AppColors.error,
                    'requests.bags_qty'.tr(),
                    request.quantity.toString(),
                  ),
                  SizedBox(height: 8.h),
                  _infoRow(
                    context,
                    request.source == RequestSource.lab
                        ? Icons.science_rounded
                        : Icons.local_hospital_rounded,
                    AppColors.secondary,
                    'requests.source'.tr(),
                    '${request.source == RequestSource.lab ? 'requests.lab'.tr() : 'requests.operation_room'.tr()} - ${request.sourceDetail}',
                  ),
                  SizedBox(height: 12.h),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAction,
                      icon: Icon(
                        isInCar
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 18.sp,
                      ),
                      label: Text(
                        isInCar
                            ? 'requests.remove_from_car'.tr()
                            : 'requests.add_to_car'.tr(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isInCar
                            ? AppColors.error
                            : AppColors.success,
                        side: BorderSide(
                          color: isInCar ? AppColors.error : AppColors.success,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.labelColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBloodTypeColor(BloodType type) {
    switch (type) {
      case BloodType.oNegative:
        return const Color(0xFFDC2626);
      case BloodType.oPositive:
        return const Color(0xFFEF4444);
      case BloodType.aPositive:
      case BloodType.aNegative:
        return const Color(0xFFE11D48);
      case BloodType.bPositive:
      case BloodType.bNegative:
        return const Color(0xFFBE123C);
      case BloodType.abPositive:
      case BloodType.abNegative:
        return const Color(0xFF9F1239);
    }
  }
}
