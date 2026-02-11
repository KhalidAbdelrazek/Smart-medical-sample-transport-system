import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'view/blood_sample_view.dart';
import 'view/blood_bag_view.dart';

/// Employee Requests Tab Page with nested tabs
/// Switches between Blood Sample and Blood Bag request views
class EmployeeRequestsTabPage extends StatefulWidget {
  const EmployeeRequestsTabPage({super.key});

  @override
  State<EmployeeRequestsTabPage> createState() =>
      _EmployeeRequestsTabPageState();
}

class _EmployeeRequestsTabPageState extends State<EmployeeRequestsTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Nested TabBar for Blood Sample / Blood Bag
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.buttonColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
            padding: EdgeInsets.all(4.w),
            tabs: [
              Tab(text: 'employee.tab_blood_samples'.tr()),
              Tab(text: 'employee.tab_blood_bags'.tr()),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [BloodSampleView(), BloodBagView()],
          ),
        ),
      ],
    );
  }
}
