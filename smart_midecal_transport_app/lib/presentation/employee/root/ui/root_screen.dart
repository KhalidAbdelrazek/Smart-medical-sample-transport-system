import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/ui/home_tab.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/my_requests_tab_page.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/ui/employee_requests_tab_page.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_state.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/widgets/notification_bottom_sheet.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/ui/profile_tab_page.dart';

/// Employee root screen with 4-tab navigation:
/// Home | Request Samples | My Requests | Profile
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  late final NotificationCubit _notificationCubit = getIt<NotificationCubit>();

  final List<String> _appbarTitles = [
    'appbar.employee_dashboard',
    'appbar.blood_sample_bags',
    'my_requests.title',
    'appbar.settings',
  ];

  @override
  void initState() {
    super.initState();
    _notificationCubit.startPolling();
  }

  @override
  void dispose() {
    _notificationCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocProvider.value(
      value: _notificationCubit,
      child: BlocListener<NotificationCubit, NotificationState>(
        listenWhen: (prev, curr) =>
            (curr.lastSuccessMessage != null &&
                curr.lastSuccessMessage != prev.lastSuccessMessage) ||
            (curr.lastErrorMessage != null &&
                curr.lastErrorMessage != prev.lastErrorMessage),
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);

          if (state.lastSuccessMessage != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.lastSuccessMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.lastErrorMessage != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.lastErrorMessage!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: scheme.error,
              ),
            );
          }

          context.read<NotificationCubit>().clearMessages();
        },
        child: Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 2,
            title: Text(
              _appbarTitles[_currentIndex].tr(),
              style: theme.textTheme.headlineMedium,
            ),
            actions: [
              BlocSelector<NotificationCubit, NotificationState, int>(
                selector: (s) => s.items.length,
                builder: (context, count) {
                  return IconButton(
                    tooltip: 'employee.notifications_title'.tr(),
                    onPressed: () {
                      // 👇 IMPORTANT: pass SAME context
                      NotificationBottomSheet.show(context);
                    },
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text(
                        count > 99 ? '99+' : '$count',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: scheme.error,
                      textColor: scheme.onError,
                      child: Icon(Icons.notifications_outlined, size: 26.sp),
                    ),
                  );
                },
              ),
              SizedBox(width: 4.w),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              EmployeeHomeTabPage(),
              EmployeeRequestsTabPage(),
              MyRequestsTabPage(),
              ProfileTabPage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
              }
            },
            height: 70.h,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'employee.nav_home'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science_rounded),
                label: 'employee.nav_requests'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'my_requests.nav_label'.tr(),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'employee.nav_profile'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
