import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:smart_midecal_transport_app/core/provider/theme_provider.dart';
import 'package:smart_midecal_transport_app/core/provider/locale_provider.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/core/routes/routes.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';

import 'core/di/di.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/my_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Bloc observer
  Bloc.observer = MyBlocObserver();

  // Dependency injection
  configureDependencies();

  // Shared preferences
  await SharedPrefService.instance.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true, // EasyLocalization will save last used locale
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(393, 837),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Medical Transport App',

          // Localization setup
          locale: localeProvider.currentLocale, // Read saved locale
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,

          // Theme setup
          theme: AppTheme().lightTheme,
          darkTheme: AppTheme().darkTheme,
          themeMode:
              themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

          // App navigation
          routes: Routes.routes,
          initialRoute: RouteNames.employerMainScreen,
          // initialRoute: SharedPrefService.instance.onBoardingViewed() ?? false ? RouteNames.root : RouteNames.onBoarding,
        );
      },
    );
  }
}
