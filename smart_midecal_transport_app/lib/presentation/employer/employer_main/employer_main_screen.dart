import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../statistics_tab/statistics_tab_page.dart';
import '../restrictions_tab/restrictions_tab_page.dart';
import '../profile_tab/employer_profile_tab_page.dart';

/// Main screen with bottom navigation for employer (admin)
/// All tabs are cached for better performance
class EmployerMainScreen extends StatefulWidget {
  const EmployerMainScreen({super.key});

  @override
  State<EmployerMainScreen> createState() => _EmployerMainScreenState();
}

class _EmployerMainScreenState extends State<EmployerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // Statistics tab - cached
          StatisticsTabPage(),
          // Restrictions tab - cached
          RestrictionsTabPage(),
          // Profile tab - cached
          EmployerProfileTabPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: theme.cardColor,
          indicatorColor: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primaryLight.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.dashboard_outlined,
                color: _currentIndex == 0
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : AppColors.labelColor,
              ),
              selectedIcon: Icon(
                Icons.dashboard_rounded,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              label: 'employer.nav_statistics'.tr(),
            ),
            NavigationDestination(
              icon: Icon(
                Icons.security_outlined,
                color: _currentIndex == 1
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : AppColors.labelColor,
              ),
              selectedIcon: Icon(
                Icons.security_rounded,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              label: 'employer.nav_restrictions'.tr(),
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: _currentIndex == 2
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : AppColors.labelColor,
              ),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              label: 'employer.nav_profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'employer.nav_statistics'.tr();
      case 1:
        return 'employer.nav_restrictions'.tr();
      case 2:
        return 'employer.nav_profile'.tr();
      default:
        return '';
    }
  }
}
