import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Error state widget with retry button
/// Shows a special "session expired" variant for token errors
class StatsErrorWidget extends StatelessWidget {
  final String message;
  final bool isTokenExpired;
  final bool isNetwork;
  final VoidCallback onRetry;
  final VoidCallback? onLogout;

  const StatsErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.isTokenExpired = false,
    this.isNetwork = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final icon = isTokenExpired
        ? Icons.lock_clock_rounded
        : isNetwork
        ? Icons.wifi_off_rounded
        : Icons.error_outline_rounded;

    final iconColor = isTokenExpired
        ? AppColors.warning
        : isNetwork
        ? AppColors.info
        : AppColors.error;

    final title = isTokenExpired
        ? 'Session Expired'
        : isNetwork
        ? 'No Connection'
        : 'Something went wrong';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40.sp, color: iconColor),
            ),
            SizedBox(height: 20.h),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            // Message
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),

            // Retry button
            if (!isTokenExpired)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('extra.try_again'.tr()),
                ),
              ),

            // Logout button for token expired
            if (isTokenExpired && onLogout != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text('extra.login_again'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: onRetry,
                child: Text('my_requests.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
