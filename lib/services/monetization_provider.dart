import 'package:flutter/foundation.dart';

class MonetizationProvider extends ChangeNotifier {
  bool _isPro = false;
  bool _adsEnabled = true;

  bool get isPro => _isPro;
  bool get adsEnabled => _adsEnabled;

  bool get shouldShowAds => _adsEnabled && !_isPro;

  void setPro(bool value, {bool shouldNotify = true}) {
    if (_isPro == value) {
      return;
    }
    _isPro = value;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void setAdsEnabled(bool value, {bool shouldNotify = true}) {
    if (_adsEnabled == value) {
      return;
    }
    _adsEnabled = value;
    if (shouldNotify) {
      notifyListeners();
    }
  }
}
