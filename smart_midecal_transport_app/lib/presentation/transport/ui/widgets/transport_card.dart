import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/presentation/transport/domain/transport_model_entity.dart';

class TransportCard extends StatelessWidget {
  final TransportModelEntity transport;
  const TransportCard({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor = transport.status == "pending"
        ? Colors.orange
        : transport.status == "urgent"
            ? Colors.red
            : Colors.green;

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.highlightColor, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "transport.transport_id".tr(namedArgs: {"id": transport.id}),
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  "transport.${transport.status}".tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.local_shipping,
                    color: theme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(transport.code, style: theme.textTheme.bodyLarge),
              ],
            ),

            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 20.sp),
                SizedBox(width: 8.w),
                Text("${"transport.pickup".tr()}: ${transport.pickup}"),
              ],
            ),

            SizedBox(height: 4.h),

            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20.sp),
                SizedBox(width: 8.w),
                Text("${"transport.dropoff".tr()}: ${transport.dropoff}"),
              ],
            ),

            SizedBox(height: 8.h),
            Divider(),
            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.person, size: 20.sp),
                SizedBox(width: 8.w),
                Text(transport.person),
                Spacer(),
                Icon(Icons.access_time, size: 20.sp),
                SizedBox(width: 4.w),
                Text(transport.time),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
