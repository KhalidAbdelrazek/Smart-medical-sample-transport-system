import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smart_midecal_transport_app/core/provider/theme_provider.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/core/routes/routes.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'core/di/di.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/my_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bloc observer
  Bloc.observer = MyBlocObserver();

  // Configure dependencies
  configureDependencies();

  // Initialize Shared Preferences
  await SharedPrefService.instance.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Your UI design resolution
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Medical Transport App',
          theme: AppTheme().lightTheme,
          darkTheme: AppTheme().darkTheme,

          // Follow system theme unless manually overridden
          themeMode: themeProvider.isDark == null
              ? ThemeMode.system
              : (themeProvider.isDark ? ThemeMode.dark : ThemeMode.light),

          // App routes
          routes: Routes.routes,
          initialRoute: RouteNames.register,
        );
      },
    );
  }
}