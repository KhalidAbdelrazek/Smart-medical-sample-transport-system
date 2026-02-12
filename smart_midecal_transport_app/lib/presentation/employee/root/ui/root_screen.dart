import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'package:smart_midecal_transport_app/presentation/employee/home/ui/home_tab.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/employee_requests_tab_page.dart';
import 'package:smart_midecal_transport_app/presentation/employee/profile/ui/profile_tab.dart';

/// Employee root screen with 3-tab navigation (Home, Requests, Profile)
/// Uses NavigationBar + IndexedStack matching employer/storage patterns
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  final List<String> _appbarTitles = [
    'appbar.employee_dashboard',
    'appbar.blood_sample_bags',
    'appbar.settings',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 2,
        title: Text(
          _appbarTitles[_currentIndex].tr(),
          style: theme.textTheme.headlineMedium,
        ),
        centerTitle: false,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          EmployeeHomeTabPage(),
          EmployeeRequestsTabPage(),
          EmployeeProfileTabPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.15),
        height: 70.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: AppColors.primaryLight,
            ),
            label: 'employee.nav_home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.science_outlined),
            selectedIcon: Icon(
              Icons.science_rounded,
              color: AppColors.primaryLight,
            ),
            label: 'employee.nav_requests'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: AppColors.primaryLight,
            ),
            label: 'employee.nav_profile'.tr(),
          ),
        ],
      ),
    );
  }
}
