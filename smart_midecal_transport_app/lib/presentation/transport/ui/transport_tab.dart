import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

class TransportTab extends StatelessWidget {
  const TransportTab({super.key});

  // Dummy transport data
  final List<Map<String, dynamic>> transports = const [
    {
      "id": "TRP001",
      "status": "pending",
      "code": "BB001234",
      "pickup": "Blood Bank - Building A",
      "dropoff": "ER - Room 301",
      "person": "Alex Johnson",
      "time": "10:30 AM",
    },
    {
      "id": "TRP002",
      "status": "urgent",
      "code": "BB001235",
      "pickup": "Storage Unit B",
      "dropoff": "ICU - Room 205",
      "person": "Maria Garcia",
      "time": "11:00 AM",
    },
    {
      "id": "TRP003",
      "status": "completed",
      "code": "BB001236",
      "pickup": "Lab C",
      "dropoff": "Surgery Room 2",
      "person": "James Wilson",
      "time": "9:15 AM",
    },
    {
      "id": "TRP004",
      "status": "pending",
      "code": "BB001237",
      "pickup": "Blood Bank - Building A",
      "dropoff": "Ward 3 - Bed 12",
      "person": "Sarah Chen",
      "time": "2:00 PM",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: 'all_status',
              style: theme.textTheme.headlineSmall,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.cardColor,
                // floatingLabelStyle: theme.textTheme.headlineSmall,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.highlightColor,width: 0.5),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'all_status',
                  child: Text("transport.all_status".tr()),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text("transport.pending".tr()),
                ),
                DropdownMenuItem(
                  value: 'urgent',
                  child: Text("transport.urgent".tr()),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text("transport.completed".tr()),
                ),
              ],
              onChanged: (value) {},
            ),

            SizedBox(height: 16.h),

            Expanded(
              child: ListView.builder(
                itemCount: transports.length,
                itemBuilder: (context, index) {
                  final transport = transports[index];

                  // Dynamic status color
                  Color statusColor = Colors.green;
                  if (transport["status"] == "pending")
                    statusColor = Colors.orange;
                  if (transport["status"] == "urgent") statusColor = Colors.red;

                  return Card(
                    color: theme.cardColor,
                    // margin: EdgeInsets.only(bottom: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.highlightColor,width: 0.5)
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "transport.transport_id".tr(
                                  namedArgs: {"id": transport["id"]},
                                ),
                                style: theme.textTheme.headlineSmall,
                              ),
                              Text(
                                "transport.${transport["status"]}".tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),
                          // Code
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 20.sp,
                                color: theme.primaryColor,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                transport["code"],
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          // Pickup
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20.sp,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "${"transport.pickup".tr()}: ${transport["pickup"]}",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),

                          SizedBox(height: 4.h),

                          // Dropoff
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20.sp,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "${"transport.dropoff".tr()}: ${transport["dropoff"]}",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),

                          SizedBox(height: 8.h),
                          Divider(height: 1),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20.sp,
                                color: theme.iconTheme.color,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                transport["person"],
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time,
                                size: 20.sp,
                                color: theme.iconTheme.color,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                transport["time"],
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 55.h),
          ],
        ),
      ),
    );
  }
}
