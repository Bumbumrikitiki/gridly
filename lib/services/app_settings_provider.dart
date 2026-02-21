import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _adsEnabledKey = 'app_settings_ads_enabled';
  static const _autoOpenPaywallKey = 'app_settings_auto_open_paywall';

  bool _initialized = false;
  bool _adsEnabled = true;
  bool _autoOpenPaywallForLockedFeatures = true;

  bool get initialized => _initialized;
  bool get adsEnabled => _adsEnabled;
  bool get autoOpenPaywallForLockedFeatures => _autoOpenPaywallForLockedFeatures;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _adsEnabled = prefs.getBool(_adsEnabledKey) ?? true;
    _autoOpenPaywallForLockedFeatures =
        prefs.getBool(_autoOpenPaywallKey) ?? true;
    notifyListeners();
  }

  Future<void> setAdsEnabled(bool value) async {
    if (_adsEnabled == value) {
      return;
    }
    _adsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsEnabledKey, value);
  }

  Future<void> setAutoOpenPaywallForLockedFeatures(bool value) async {
    if (_autoOpenPaywallForLockedFeatures == value) {
      return;
    }
    _autoOpenPaywallForLockedFeatures = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoOpenPaywallKey, value);
  }
}
