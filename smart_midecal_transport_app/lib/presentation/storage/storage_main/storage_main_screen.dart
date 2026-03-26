import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../home_tab/home_tab_page.dart';
import '../requests_tab/ui/requests_tab_page.dart';
import '../profile_tab/ui/profile_tab_page.dart';

/// Main screen with bottom navigation for storage employee
/// - Home & Profile tabs: Cached (data persists)
/// - Requests tab: Recreated each time (cubit disposed to save memory)
class StorageMainScreen extends StatefulWidget {
  const StorageMainScreen({super.key});

  @override
  State<StorageMainScreen> createState() => _StorageMainScreenState();
}

class _StorageMainScreenState extends State<StorageMainScreen> {
  int _currentIndex = 0;

  /// Key to force rebuild of Requests tab each time
  int _requestsTabKey = 0;

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
        children: [
          // Home tab - cached
          const HomeTabPage(),
          // Requests tab - recreated each visit via unique key
          KeyedSubtree(
            key: ValueKey('requests_$_requestsTabKey'),
            child: const RequestsTabPage(),
          ),
          // Profile tab - cached
          const ProfileTabPage(),
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
              // If switching TO requests tab, increment key to force rebuild
              if (index == 1 && _currentIndex != 1) {
                _requestsTabKey++;
              }
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
                Icons.home_outlined,
                color: _currentIndex == 0
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : AppColors.labelColor,
              ),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              label: 'nav.home'.tr(),
            ),
            NavigationDestination(
              icon: Icon(
                Icons.article_outlined,
                color: _currentIndex == 1
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : AppColors.labelColor,
              ),
              selectedIcon: Icon(
                Icons.article_rounded,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              label: 'nav.requests'.tr(),
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
              label: 'nav.profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'nav.home'.tr();
      case 1:
        return 'nav.requests'.tr();
      case 2:
        return 'nav.profile'.tr();
      default:
        return '';
    }
  }
}
