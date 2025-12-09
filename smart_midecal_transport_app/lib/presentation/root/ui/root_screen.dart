import 'package:flutter/material.dart';
import 'package:smart_midecal_transport_app/core/assets/app_assets.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/core/utils/constant.dart';
import 'package:smart_midecal_transport_app/presentation/home/ui/home_tab.dart';
import 'package:smart_midecal_transport_app/presentation/request%20sample/ui/request_sample_tab.dart';
import 'package:smart_midecal_transport_app/presentation/root/ui/widgets/bottombar_item.dart';
import 'package:smart_midecal_transport_app/presentation/settings/ui/settings_tab.dart';
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
      "title": "Home",
    },
    {
      "icon": AppAssets.request,
      "active_icon": AppAssets.activeRequest,
      "page": RequestSampleTab(),
      "title": "Request Sample",
    },
    {
      "icon": AppAssets.transport,
      "active_icon": AppAssets.activeTransport,
      "page": TransportTab(),
      "title": "Transports",
    },
    {
      "icon": AppAssets.settings,
      "active_icon": AppAssets.activeSettings,
      "page": SettingsTab(),
      "title": "Settings",
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
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).cardColor,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(Icons.menu, color: Theme.of(context).primaryColor),
            );
          },
        ),
        title: Text(
          barItems[activeTab]["title"],
          style: TextTheme.of(context).headlineMedium,
        ),
        centerTitle: true,
      ),

      // drawer: MyDrawer(onTap: (p0) => onTap(p0)),
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
      height: 55,
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(25, 0, 25, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withAlpha(25),
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
