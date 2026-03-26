import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/entities/tranport_req_entities.dart';

/// A modern hospital-style card for a single transport request.
///
/// • Shows Sample Code, Patient Name, Blood Type badge, Room, Status badge, Date.
/// • If status == PENDING → shows Cancel button.
/// • [isCancelling] → shows CircularProgressIndicator inside the button.
class TransportRequestCard extends StatelessWidget {
  final TransportMyRequestEntity request;
  final bool isCancelling;
  final VoidCallback? onCancel;

  const TransportRequestCard({
    super.key,
    required this.request,
    required this.isCancelling,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = (request.requestStatus ?? '').toUpperCase();
    final isPending = status == 'PENDING';
    final statusColor = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkColor : AppColors.cardLightColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.cardDarkStrokeColor
              : AppColors.cardLightStrokeColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Accent bar (status colour) ────────────────────────────────
            Container(width: 5.w, color: statusColor),

            // ── Card content ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1 – Sample code + Status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${('my_requests.sample_code'.tr())}: ${request.sampleCode ?? '—'}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _StatusBadge(status: status, color: statusColor),
                      ],
                    ),

                    SizedBox(height: 6.h),

                    // Row 2 – Patient name
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14.sp, color: AppColors.labelColor),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            request.patientName ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.h),

                    // Row 3 – Blood type | Room | Date
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (request.bloodType != null)
                          _BloodTypeBadge(bloodType: request.bloodType!),
                        _InfoChip(
                          icon: Icons.meeting_room_outlined,
                          label:
                              '${('my_requests.room'.tr())}: ${request.roomNumber ?? '—'}',
                        ),
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: _formatDate(request.createdAt),
                        ),
                      ],
                    ),

                    // Row 4 – Cancel button (PENDING only)
                    if (isPending) ...[
                      SizedBox(height: 10.h),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: SizedBox(
                          height: 34.h,
                          child: isCancelling
                              ? Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  child: SizedBox(
                                    width: 22.w,
                                    height: 22.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.error,
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: onCancel,
                                  icon: Icon(Icons.cancel_outlined, size: 15.sp),
                                  label: Text(
                                    'my_requests.cancel'.tr(),
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                        color: AppColors.error, width: 1),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8.r),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
      case 'REQUESTED':
        return AppColors.warning;
      case 'IN_TRANSIT':
      case 'ASSIGNED':
      case 'OUT_FOR_DELIVERY':
        return AppColors.info;
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.labelColor;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = _label(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'PENDING':
        return 'my_requests.status_pending'.tr();
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return 'my_requests.status_in_transit'.tr();
      case 'DELIVERED':
      case 'COMPLETED':
        return 'my_requests.status_delivered'.tr();
      case 'CANCELLED':
        return 'my_requests.status_cancelled'.tr();
      default:
        return status;
    }
  }
}

class _BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  const _BloodTypeBadge({required this.bloodType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_rounded,
              size: 11.sp,
              color: AppColors.error.withValues(alpha: 0.8)),
          SizedBox(width: 3.w),
          Text(
            bloodType,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: AppColors.labelColor),
        SizedBox(width: 3.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.labelColor,
          ),
        ),
      ],
    );
  }
}
