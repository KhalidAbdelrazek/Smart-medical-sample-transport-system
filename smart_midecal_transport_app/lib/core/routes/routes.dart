import 'package:flutter/material.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/admin_login_screen.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/employee_login_screen.dart';
import 'package:smart_midecal_transport_app/presentation/employer/employer_main/employer_main_screen.dart';
import 'package:smart_midecal_transport_app/presentation/onboarding/ui/onboarding_screen.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/root_screen.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/ui/storage_main_screen.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/view/returned_cars_shell.dart';

class Routes {
  static Map<String, Widget Function(BuildContext)> routes = {
    RouteNames.register: (_) => const EmployeeLoginScreen(),
    RouteNames.adminLogin: (_) => const AdminLoginScreen(),
    RouteNames.onBoarding: (_) => OnboardingScreen(),
    RouteNames.root: (_) => RootScreen(),
    RouteNames.storageScreen: (_) => const ReturnedCarsShell(),
    RouteNames.employerMainScreen: (_) => EmployerMainScreen(),
  };
}
