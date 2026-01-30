import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cubit/request_blood_view_model.dart';

class RecentRequestsList extends StatelessWidget {
  final RequestBloodViewModel requestBloodViewModel;
  const RecentRequestsList({super.key, required this.requestBloodViewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ...requestBloodViewModel.recentRequests.map((e) {
          // Determine status color and localized text
          final status = e["status"]!.toLowerCase();
          Color statusColor;
          String statusText;

          if (status == "pending") {
            statusColor = Colors.orange;
            statusText = "request_sample.status_pending".tr();
          } else {
            statusColor = Colors.green;
            statusText = "request_sample.status_completed".tr();
          }

          return Container(
            margin: EdgeInsets.only(bottom: 15.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18.r),
              border: BoxBorder.all(color: theme.highlightColor, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e["name"]!,
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      e["blood"]!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        SizedBox(width: 6.w),
                        Text(
                          e["time"]!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
