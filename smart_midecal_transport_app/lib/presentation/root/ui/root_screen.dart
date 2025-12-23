import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/assets/app_assets.dart';
import 'package:smart_midecal_transport_app/core/provider/locale_provider.dart';
import 'package:smart_midecal_transport_app/core/provider/theme_provider.dart';
import 'package:smart_midecal_transport_app/core/utils/constant.dart';
import 'package:smart_midecal_transport_app/presentation/home/ui/home_tab.dart';
import 'package:smart_midecal_transport_app/presentation/profile/ui/profile_tab.dart';
import 'package:smart_midecal_transport_app/presentation/request%20sample/ui/request_sample_tab.dart';
import 'package:smart_midecal_transport_app/presentation/root/ui/widgets/bottombar_item.dart';
import 'package:smart_midecal_transport_app/presentation/transport/ui/transport_tab.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> with TickerProviderStateMixin {
  int activeTab = 0;
  bool showFloatingActionButton = true;

  late final AnimationController _controller = AnimationController(
    duration: Duration(milliseconds: animatedBodyMs),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get barItems => [
    {
      "icon": AppAssets.home,
      "active_icon": AppAssets.actievHome,
      "page": HomeTab(),
      "title": "bottomNavBar.home".tr(),
      "appbarTitle": "appbar.employee_dashboard".tr(),
    },
    {
      "icon": AppAssets.request,
      "active_icon": AppAssets.activeRequest,
      "page": RequestSampleTab(),
      "title": "bottomNavBar.request_sample".tr(),
      "appbarTitle": "appbar.blood_sample_bags".tr(),
    },
    {
      "icon": AppAssets.transport,
      "active_icon": AppAssets.activeTransport,
      "page": TransportTab(),
      "title": "bottomNavBar.transports".tr(),
      "appbarTitle": "appbar.active_transports".tr(),
    },
    {
      "icon": AppAssets.settings,
      "active_icon": AppAssets.activeSettings,
      "page": ProfileTab(),
      "title": "bottomNavBar.settings".tr(),
      "appbarTitle": "appbar.settings".tr(),
    },
  ];

  void onPageChanged(int index) async {
    if (activeTab == index) return;
    
    _controller.reset();
    setState(() {
      activeTab = index;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Allows content to go behind bottom bar
      appBar: AppBar(
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
              color: theme.iconTheme.color,
            ),
          ),
          IconButton(
            onPressed: () => localeProvider.toggleLocale(context),
            icon: Icon(Icons.language, color: theme.iconTheme.color),
          ),
          SizedBox(width: 8.w),
        ],
        title: Text(
          barItems[activeTab]["appbarTitle"],
          style: theme.textTheme.headlineMedium,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: getBarPage(),
      bottomNavigationBar: getBottomBar(),
    );
  }

  Widget getBarPage() {
    return IndexedStack(
      index: activeTab,
      children: List.generate(
        barItems.length,
        (index) => FadeTransition(
          opacity: _animation, 
          child: barItems[index]["page"]
        ),
      ),
    );
  }

  Widget getBottomBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95), // Slight transparency
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              barItems.length,
              (index) => BottomBarItem(
                activeTab == index
                    ? barItems[index]["active_icon"]
                    : barItems[index]["icon"],
                "",
                title: barItems[index]["title"],
                isActive: activeTab == index,
                activeColor: theme.primaryColor,
                color: theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey,
                onTap: () {
                  onPageChanged(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
