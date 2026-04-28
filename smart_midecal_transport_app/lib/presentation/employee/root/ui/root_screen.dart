import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'package:smart_midecal_transport_app/presentation/employee/home/ui/home_tab.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/my_requests_tab_page.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/data/return_flow_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/ui/cubit/return_polling_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/ui/cubit/return_polling_state.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/ui/widgets/return_popup_widget.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/ui/employee_requests_tab_page.dart';
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
  late final ReturnPollingCubit _returnPollingCubit;

  final List<String> _appbarTitles = [
    'appbar.employee_dashboard',
    'appbar.blood_sample_bags',
    'my_requests.title',
    'appbar.settings',
  ];

  @override
  void initState() {
    super.initState();
    _returnPollingCubit = ReturnPollingCubit(
      ReturnFlowRemoteDataSource(apiManager: getIt<ApiManager>()),
    )..startPolling();
  }

  @override
  void dispose() {
    _returnPollingCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _returnPollingCubit,
      child: BlocConsumer<ReturnPollingCubit, ReturnPollingState>(
        listenWhen: (previous, current) =>
            previous.toastMessage != current.toastMessage ||
            previous.tokenExpired != current.tokenExpired,
        listener: (context, state) {
          if (state.toastMessage != null) {
            final toast = state.toastMessage!;
            final rendered = toast.startsWith('return_popup.') ? toast.tr() : toast;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(rendered),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<ReturnPollingCubit>().clearToast();
          }

          if (state.tokenExpired) {
            context.read<ReturnPollingCubit>().clearTokenExpired();
          }
        },
        builder: (context, state) {
          final scaffold = Scaffold(
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
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryLight,
                  ),
                  label: 'my_requests.nav_label'.tr(),
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

          if (!state.hasBlockingPopup) {
            return scaffold;
          }

          return Stack(
            children: [
              scaffold,
              ReturnPopupWidget(
                samples: state.activeSamples,
                isSubmitting: state.isConfirming,
                onConfirm: () => context.read<ReturnPollingCubit>().confirmHandoff(),
              ),
            ],
          );
        },
      ),
    );
  }
}
