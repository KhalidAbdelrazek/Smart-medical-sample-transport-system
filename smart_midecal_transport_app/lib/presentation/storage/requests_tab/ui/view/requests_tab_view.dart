import 'package:flutter/material.dart';

import 'blood_samples_view.dart';
// import 'return_approval_view.dart';

/// Requests Tab View — Contains tabs for Transport Requests and Return Approval
class RequestsTabView extends StatefulWidget {
  const RequestsTabView({super.key});

  @override
  State<RequestsTabView> createState() => _RequestsTabViewState();
}

class _RequestsTabViewState extends State<RequestsTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        // Container(
        //   color: theme.cardColor,
        //   child: TabBar(
        //     controller: _tabController,
        //     indicatorColor: isDark
        //         ? AppColors.primaryDark
        //         : AppColors.primaryLight,
        //     labelColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        //     unselectedLabelColor: AppColors.labelColor,
        //     tabs: [
        //       Tab(
        //         text: 'requests.transport_requests'.tr(),
        //         icon: Icon(Icons.local_shipping_outlined, size: 20.sp),
        //       ),
        //       // Tab(
        //       //   text: 'requests.return_approval'.tr(),
        //       //   icon: Icon(Icons.assignment_return_outlined, size: 20.sp),
        //       // ),
        //     ],
        //   ),
        // ),

        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              // Transport Requests Tab
              BloodSamplesView(),

              // Return Approval Tab
              // ReturnApprovalView(),
            ],
          ),
        ),
      ],
    );
  }
}
