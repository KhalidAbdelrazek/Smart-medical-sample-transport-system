import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/blood_bags_cubit.dart';
import 'cubit/blood_bags_state.dart';
import 'cubit/blood_samples_cubit.dart';
import 'cubit/blood_samples_state.dart';
import 'view/blood_bags_view.dart';
import 'view/blood_samples_view.dart';

/// Requests Tab Page with Blood Bags and Blood Samples sub-tabs
class RequestsTabPage extends StatefulWidget {
  const RequestsTabPage({super.key});

  @override
  State<RequestsTabPage> createState() => _RequestsTabPageState();
}

class _RequestsTabPageState extends State<RequestsTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BloodBagsCubit _bloodBagsCubit;
  late BloodSamplesCubit _bloodSamplesCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bloodBagsCubit = BloodBagsCubit()..loadRequests();
    _bloodSamplesCubit = BloodSamplesCubit()..loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloodBagsCubit.close();
    _bloodSamplesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloodBagsCubit),
        BlocProvider.value(value: _bloodSamplesCubit),
      ],
      child: Column(
        children: [
          // Sub-tabs
          Container(
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              dividerColor: Colors.transparent,
              labelColor: isDark ? AppColors.appDarkBgColor : Colors.white,
              unselectedLabelColor: AppColors.labelColor,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.all(4.w),
              tabs: [
                _buildTab(
                  icon: Icons.bloodtype_rounded,
                  label: 'requests.blood_bags'.tr(),
                  cubit: _bloodBagsCubit,
                ),
                _buildTab(
                  icon: Icons.science_rounded,
                  label: 'requests.blood_samples'.tr(),
                  cubit: _bloodSamplesCubit,
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [BloodBagsView(), BloodSamplesView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required dynamic cubit,
  }) {
    return Tab(
      child: BlocBuilder(
        bloc: cubit,
        builder: (context, state) {
          int pendingCount = 0;
          if (state is BloodBagsLoaded) pendingCount = state.pendingCount;
          if (state is BloodSamplesLoaded) pendingCount = state.pendingCount;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp),
              SizedBox(width: 6.w),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              if (pendingCount > 0) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
