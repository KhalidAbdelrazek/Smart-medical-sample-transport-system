import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static final SharedPrefService _instance = SharedPrefService._internal();
  late SharedPreferences _prefs;

  static const String onBoardingKey = 'onBoardingKey';

  SharedPrefService._internal();

  static SharedPrefService get instance => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // todo: onBoarding =>
  bool? onBoardingViewed() {
    return _prefs.getBool(onBoardingKey);
  }

  Future<void> setOnboardingViewed(bool value) async {
    await _prefs.setBool(onBoardingKey, value);

  }
}
