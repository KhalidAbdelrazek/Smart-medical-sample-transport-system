import 'package:flutter/cupertino.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/sign_in_screen.dart';
import 'package:smart_midecal_transport_app/presentation/employer/employer_main/employer_main_screen.dart';
import 'package:smart_midecal_transport_app/presentation/onboarding/ui/onboarding_screen.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/root_screen.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/storage_main_screen.dart';
class Routes {
  static Map<String, Widget Function(BuildContext)> routes = {
    RouteNames.register: (_) => SignInScreen(),
    RouteNames.onBoarding: (_) => OnboardingScreen(),
    RouteNames.root: (_) => RootScreen(),
    RouteNames.storageScreen: (_) => const StorageMainScreen(),
    RouteNames.employerMainScreen: (_) => EmployerMainScreen()
  };
}
