import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';

/// Status badge color configuration
class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

_StatusConfig _statusConfig(String? status) {
  switch (status?.toUpperCase()) {
    case 'PENDING':
    case 'REQUESTED':
      return _StatusConfig(
        color: AppColors.warning,
        icon: Icons.hourglass_empty_rounded,
        label: status ?? 'Unknown',
      );
    case 'LOADED':
    case 'LOADED_FOR_RETURN':
      return _StatusConfig(
        color: AppColors.primaryLight,
        icon: Icons.inventory_2_rounded,
        label: status ?? 'Unknown',
      );
    case 'APPROVED':
    case 'OUT_FOR_DELIVERY':
    case 'IN_TRANSIT':
      return _StatusConfig(
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
        label: status ?? 'Unknown',
      );
    case 'REJECTED':
    case 'CANCELLED':
      return _StatusConfig(
        color: AppColors.error,
        icon: Icons.cancel_rounded,
        label: status ?? 'Unknown',
      );
    default:
      return _StatusConfig(
        color: AppColors.labelColor,
        icon: Icons.info_outline_rounded,
        label: status ?? 'Unknown',
      );
  }
}

/// Card for a single transport request (blood sample only)
class BloodSampleCard extends StatelessWidget {
  final TransportRequestEntity request;

  /// Whether the "Add to Car" API call is in progress for this card.
  final bool isActionLoading;

  /// Null when car is full, request is already in transit, or action is loading.
  final VoidCallback? onAddToCar;

  /// Called when storage removes a LOADED sample from the car.
  /// Null when the sample is not in LOADED status.
  final VoidCallback? onRemoveFromCar;

  final int index;

  const BloodSampleCard({
    super.key,
    required this.request,
    this.isActionLoading = false,
    this.onAddToCar,
    this.onRemoveFromCar,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sample = request.sample;
    final statusCfg = _statusConfig(request.status);
    final isPending =
        request.status?.toUpperCase() == 'PENDING' ||
        request.status?.toUpperCase() == 'REQUESTED';
    final isLoaded =
        request.status?.toUpperCase() == 'LOADED' ||
        request.status?.toUpperCase() == 'LOADED_FOR_RETURN';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: EdgeInsetsDirectional.only(bottom: 14.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: statusCfg.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isLoaded
                    ? AppColors.primaryLight.withValues(alpha: 0.08)
                    : AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isLoaded ? AppColors.primaryLight : AppColors.info,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      isLoaded
                          ? Icons.inventory_2_rounded
                          : Icons.science_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sample?.sampleCode ?? request.id ?? '—',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (request.id != null)
                          Text(
                            '${'employee.id'.tr()}: ${request.id}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.labelColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusCfg.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: statusCfg.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusCfg.icon,
                          color: statusCfg.color,
                          size: 13.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          statusCfg.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusCfg.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  if (sample?.patientName != null)
                    _infoRow(
                      context,
                      Icons.person_rounded,
                      AppColors.primaryLight,
                      'requests.patient_name'.tr(),
                      sample!.patientName!,
                    ),
                  if (sample?.patientId != null) ...[
                    SizedBox(height: 8.h),
                    _infoRow(
                      context,
                      Icons.badge_rounded,
                      AppColors.secondary,
                      'requests.patient_id'.tr(),
                      sample!.patientId!,
                    ),
                  ],
                  if (sample?.bloodType != null) ...[
                    SizedBox(height: 8.h),
                    _infoRow(
                      context,
                      Icons.bloodtype_rounded,
                      AppColors.error,
                      'requests.blood_type'.tr(),
                      sample!.bloodType!,
                    ),
                  ],
                  if (request.roomNumber != null) ...[
                    SizedBox(height: 8.h),
                    _infoRow(
                      context,
                      Icons.meeting_room_rounded,
                      AppColors.warning,
                      'requests.room'.tr(),
                      request.roomNumber!,
                    ),
                  ],
                  if (request.requestedByName != null) ...[
                    SizedBox(height: 8.h),
                    _infoRow(
                      context,
                      Icons.account_circle_rounded,
                      AppColors.labelColor,
                      'requests.requested_by'.tr(),
                      request.requestedByName!,
                    ),
                  ],
                  if (request.createdAt != null) ...[
                    SizedBox(height: 8.h),
                    _infoRow(
                      context,
                      Icons.schedule_rounded,
                      AppColors.labelColor,
                      'requests.created_at'.tr(),
                      _formatDate(request.createdAt!),
                    ),
                  ],

                  // ── Add to Car Button (PENDING only) ─────────────────────
                  if (isPending) ...[
                    SizedBox(height: 14.h),
                    SizedBox(
                      width: double.infinity,
                      child: isActionLoading
                          ? const _LoadingButton(
                              color: AppColors.success,
                              labelKey: 'requests.adding',
                            )
                          : FilledButton.icon(
                              onPressed: onAddToCar,
                              icon: Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18.sp,
                              ),
                              label: Text('requests.add_to_car'.tr()),
                              style: FilledButton.styleFrom(
                                backgroundColor: onAddToCar == null
                                    ? AppColors.labelColor.withValues(
                                        alpha: 0.4,
                                      )
                                    : AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    EdgeInsets.symmetric(vertical: 13.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                    ),
                  ],

                  // ── Remove from Car Button (LOADED only) ─────────────────
                  if (isLoaded) ...[
                    SizedBox(height: 14.h),
                    SizedBox(
                      width: double.infinity,
                      child: isActionLoading
                          ? const _LoadingButton(
                              color: AppColors.error,
                              labelKey: 'requests.removing',
                            )
                          : OutlinedButton.icon(
                              onPressed: onRemoveFromCar,
                              icon: Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18.sp,
                                color: AppColors.error,
                              ),
                              label: Text(
                                'requests.remove_from_car'.tr(),
                                style: TextStyle(color: AppColors.error),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.6),
                                ),
                                padding:
                                    EdgeInsets.symmetric(vertical: 13.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                    ),
                  ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 17.sp),
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} – ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

/// Small loading indicator shown in the button while an action is running.
class _LoadingButton extends StatelessWidget {
  final Color color;
  final String labelKey;

  const _LoadingButton({
    required this.color,
    required this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            labelKey.tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
