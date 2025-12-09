import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class LocaleProvider extends ChangeNotifier {
  final String _langKey = 'appLang';

  late SharedPreferences _prefs;
  Locale _currentLocale = const Locale('en'); // default English

  Locale get currentLocale => _currentLocale;

  LocaleProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    final savedLang = _prefs.getString(_langKey);

    if (savedLang != null) {
      _currentLocale = Locale(savedLang);
    }

    notifyListeners();
  }

  Future<void> setEnglish(BuildContext context) async {
    _currentLocale = const Locale('en');
    await _prefs.setString(_langKey, 'en');
    await context.setLocale(const Locale('en'));
    notifyListeners();
  }

  Future<void> setArabic(BuildContext context) async {
    _currentLocale = const Locale('ar');
    await _prefs.setString(_langKey, 'ar');
    await context.setLocale(const Locale('ar'));
    notifyListeners();
  }

  Future<void> toggleLocale(BuildContext context) async {
    if (_currentLocale.languageCode == 'en') {
      await setArabic(context);
    } else {
      await setEnglish(context);
    }
    print(_currentLocale);
  }
}
