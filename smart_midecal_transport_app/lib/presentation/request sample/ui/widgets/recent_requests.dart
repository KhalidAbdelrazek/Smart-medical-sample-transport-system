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
      textDirection: TextDirection.ltr,
      children: requestBloodViewModel.recentRequests.map((e) {
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
            textDirection: TextDirection.ltr,

            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    e["name"]!,
                    style: theme.textTheme.headlineSmall,
                    textDirection: TextDirection.ltr,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    e["blood"]!,
                    style: theme.textTheme.bodyMedium,
                    textDirection: TextDirection.ltr,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    textDirection: TextDirection.ltr,

                    children: [
                      const Icon(Icons.access_time, size: 16),
                      SizedBox(width: 6.w),
                      Text(
                        e["time"]!,
                        style: theme.textTheme.bodySmall,
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                e["status"]!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: e["status"] == "Pending"
                      ? Colors.orange
                      : Colors.green,
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
