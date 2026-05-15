import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/return_request_entity.dart';

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
  switch (status?.toLowerCase()) {
    case 'pending':
      return _StatusConfig(
        color: AppColors.warning,
        icon: Icons.hourglass_empty_rounded,
        label: 'employee.pendingg'.tr(),
      );
    case 'approved':
      return _StatusConfig(
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
        label: 'employee.approved'.tr(),
      );
    case 'rejected':
      return _StatusConfig(
        color: AppColors.error,
        icon: Icons.cancel_rounded,
        label: 'employee.rejected'.tr(),
      );
    default:
      return _StatusConfig(
        color: AppColors.labelColor,
        icon: Icons.info_outline_rounded,
        label: status ?? 'employee.unknown'.tr(),
      );
  }
}

/// Card for a single return request
class ReturnRequestCard extends StatelessWidget {
  final ReturnRequestEntity returnRequest;

  /// Whether the approve/reject action is in progress for this card.
  final bool isActionLoading;

  /// Callbacks for approve and reject actions
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  final int index;

  const ReturnRequestCard({
    super.key,
    required this.returnRequest,
    this.isActionLoading = false,
    this.onApprove,
    this.onReject,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sample = returnRequest.sample;
    final doctor = returnRequest.requestedBy;
    final statusCfg = _statusConfig(returnRequest.status);
    final isPending = returnRequest.status.toLowerCase() == 'pending';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
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
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.assignment_return_rounded,
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
                          sample.sampleCode.isNotEmpty
                              ? sample.sampleCode
                              : returnRequest.id,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${'employee.id'.tr()}: ${returnRequest.id}',
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
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusCfg.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: statusCfg.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusCfg.icon,
                          color: statusCfg.color,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          statusCfg.label.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusCfg.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sample Info
                  _InfoRow(
                    icon: Icons.science_rounded,
                    label: 'return_approval.patient'.tr(),
                    value: sample.patientName,
                  ),
                  SizedBox(height: 8.h),
                  _InfoRow(
                    icon: Icons.bloodtype_rounded,
                    label: 'return_approval.blood_type'.tr(),
                    value: sample.bloodType,
                  ),
                  SizedBox(height: 8.h),

                  // Doctor Info
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'return_approval.doctor'.tr(),
                    value: doctor.name,
                  ),
                  SizedBox(height: 8.h),
                  _InfoRow(
                    icon: Icons.email_rounded,
                    label: 'return_approval.email'.tr(),
                    value: doctor.email,
                  ),
                  SizedBox(height: 12.h),

                  // Request Time
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'return_approval.request_time'.tr(),
                    value: _formatDateTime(returnRequest.createdAt),
                  ),

                  // Action Buttons (only for pending requests)
                  if (isPending) ...[
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        // Approve Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isActionLoading ? null : onApprove,
                            icon: Icon(
                              Icons.check_rounded,
                              size: 18.sp,
                              color: Colors.white,
                            ),
                            label: Text('return_approval.approve'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Reject Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isActionLoading ? null : onReject,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18.sp,
                              color: Colors.white,
                            ),
                            label: Text('return_approval.reject'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}${'employee.d_ago'.tr()}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${'employee.h_ago'.tr()}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${'employee.m_ago'.tr()}';
    } else {
      return 'employee.just_now'.tr();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.labelColor),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
