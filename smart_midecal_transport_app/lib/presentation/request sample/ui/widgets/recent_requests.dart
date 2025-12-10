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
      children: requestBloodViewModel.recentRequests.map((e) {
        return Container(
          margin: EdgeInsets.only(bottom: 15.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e["name"]!, style: theme.textTheme.headlineSmall),
                  SizedBox(height: 6.h),
                  Text(e["blood"]!, style: theme.textTheme.bodyMedium),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      SizedBox(width: 6.w),
                      Text(e["time"]!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              Text(
                e["status"]!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: e["status"] == "pending" ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
