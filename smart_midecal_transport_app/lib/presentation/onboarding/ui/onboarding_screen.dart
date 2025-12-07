import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:smart_midecal_transport_app/core/assets/app_assets.dart';
import 'package:smart_midecal_transport_app/presentation/onboarding/ui/widgets/travel_intro_screen.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/shared_pref_services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      showBottomPart: false,
      showNextButton: false,
      showDoneButton: false,
      showBackButton: false,

      rawPages: [
        TravelIntroScreen(
          backgroundImage: AppAssets.onBoarding1,
          title: "onboarding.onboarding_1_title".tr(),
          description: "onboarding.onboarding_1_description".tr(),
          nextText: "onboarding.next_button".tr(),
          onNextPressed: () => introKey.currentState?.next(),

        ),

        TravelIntroScreen(
          backgroundImage: AppAssets.onBoarding2,
          title: "onboarding.onboarding_2_title".tr(),
          description: "onboarding.onboarding_2_description".tr(),
          nextText: "onboarding.next_button".tr(),
          onNextPressed: () => introKey.currentState?.next(),
          backText: "onboarding.back_button".tr(),
          onBackPressed: () => introKey.currentState?.previous(),
        ),

        TravelIntroScreen(
          backgroundImage: AppAssets.onBoarding3,
          title: "onboarding.onboarding_3_title".tr(),
          description: "onboarding.onboarding_3_description".tr(),
          nextText: "onboarding.next_button".tr(),
          backText: "onboarding.back_button".tr(),
          onNextPressed: () => introKey.currentState?.next(),
          onBackPressed: () => introKey.currentState?.previous(),
        ),

        TravelIntroScreen(
          backgroundImage: AppAssets.onBoarding4,
          title: "onboarding.onboarding_4_title".tr(),
          description: "onboarding.onboarding_4_description".tr(),
          nextText: "onboarding.finish_button".tr(),
          backText: "onboarding.back_button".tr(),
          onNextPressed: () async {
            await SharedPrefService.instance.setOnboardingViewed(true);
            Navigator.pushReplacementNamed(context, RouteNames.register);
          },
          onBackPressed: () => introKey.currentState?.previous(),
        ),
      ],
    );
  }
}
