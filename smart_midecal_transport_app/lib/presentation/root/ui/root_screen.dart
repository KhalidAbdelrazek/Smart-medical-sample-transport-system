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
    _controller.stop();
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

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => localeProvider.toggleLocale(context),
                icon: const Icon(Icons.language),
              );
            },
          ),
        ],
        title: Text(
          barItems[activeTab]["appbarTitle"],
        ),
        centerTitle: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: getBarPage(),
      floatingActionButton: getBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget getBarPage() {
    return IndexedStack(
      index: activeTab,
      children: List.generate(
        barItems.length,
        (index) =>
            FadeTransition(child: barItems[index]["page"], opacity: _animation),
      ),
    );
  }

  Widget getBottomBar() {
    return Container(
      height: 55.h,
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(25.w, 0, 25.w, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            blurRadius: 1,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          barItems.length,
          (index) => BottomBarItem(
            activeTab == index
                ? barItems[index]["active_icon"]
                : barItems[index]["icon"],
            "",
            isActive: activeTab == index,
            activeColor: Theme.of(context).primaryColor,
            onTap: () {
              onPageChanged(index);
            },
          ),
        ),
      ),
    );
  }

  void onTap(int index) {
    setState(() {
      activeTab = index;
    });
  }
}
