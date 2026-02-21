import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const Set<String> _productIds = <String>{
    'gridly_pro_monthly',
    'gridly_pro_yearly',
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final bool _firebaseEnabled;
  final String _androidPackageName;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _initialized = false;
  bool _storeAvailable = false;
  bool _isLoading = false;
  bool _isPurchaseInProgress = false;
  bool _isRestoring = false;
  bool _hasActiveEntitlement = false;
  String? _errorMessage;
  List<ProductDetails> _products = const <ProductDetails>[];

  String? _currentUid;

  SubscriptionProvider({
    required bool firebaseEnabled,
    required String androidPackageName,
  }) : _firebaseEnabled = firebaseEnabled,
       _androidPackageName = androidPackageName;

  bool get initialized => _initialized;
  bool get storeAvailable => _storeAvailable;
  bool get isLoading => _isLoading;
  bool get isPurchaseInProgress => _isPurchaseInProgress;
  bool get isRestoring => _isRestoring;
  bool get hasActiveEntitlement => _hasActiveEntitlement;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  bool get canSellSubscriptions => _storeAvailable && _products.isNotEmpty;

  void setSignedInUser(String? uid) {
    if (_currentUid == uid) {
      return;
    }
    _currentUid = uid;
    if (uid == null) {
      _hasActiveEntitlement = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (kIsWeb) {
      _storeAvailable = false;
      _errorMessage =
          'Zakupy subskrypcji są dostępne tylko w aplikacji mobilnej ze sklepu.';
      notifyListeners();
      return;
    }

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        _isPurchaseInProgress = false;
        _errorMessage = 'Błąd strumienia zakupów: $error';
        notifyListeners();
      },
    );

    await refreshProducts();
  }

  Future<void> refreshProducts() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _products = const <ProductDetails>[];
        _setLoading(false);
        notifyListeners();
        return;
      }

      final response = await _inAppPurchase.queryProductDetails(_productIds);
      if (response.error != null) {
        _errorMessage = response.error!.message;
      }
      if (response.notFoundIDs.isNotEmpty) {
        _errorMessage =
            'Brak produktów w sklepie: ${response.notFoundIDs.join(', ')}';
      }

      _products = response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } catch (e) {
      _errorMessage = 'Nie udało się pobrać produktów: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (!_storeAvailable) {
      _errorMessage = 'Sklep niedostępny na tym urządzeniu.';
      notifyListeners();
      return;
    }

    if (_currentUid == null) {
      _errorMessage = 'Zaloguj się, aby kupić subskrypcję.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _isPurchaseInProgress = true;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _isPurchaseInProgress = false;
      _errorMessage = 'Nie udało się rozpocząć zakupu: $e';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _errorMessage = 'Sklep niedostępny na tym urządzeniu.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _isRestoring = true;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _errorMessage = 'Nie udało się przywrócić zakupów: $e';
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isPurchaseInProgress = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyWithBackend(purchase);
          _isPurchaseInProgress = false;
          break;
        case PurchaseStatus.error:
          _errorMessage = purchase.error?.message ?? 'Błąd zakupu.';
          _isPurchaseInProgress = false;
          break;
        case PurchaseStatus.canceled:
          _isPurchaseInProgress = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  Future<void> _verifyWithBackend(PurchaseDetails purchase) async {
    if (!_firebaseEnabled) {
      _hasActiveEntitlement = true;
      _errorMessage =
          'Firebase nie jest skonfigurowany. Zakup lokalnie wykryty, ale brak walidacji serwerowej.';
      return;
    }

    if (_currentUid == null) {
      _errorMessage =
          'Zakup wykryty, ale brak zalogowanego konta użytkownika do walidacji.';
      _hasActiveEntitlement = false;
      return;
    }

    final purchaseToken = _extractPurchaseToken(purchase);
    if (purchaseToken == null || purchaseToken.isEmpty) {
      _errorMessage =
          'Zakup wykryty, ale nie udało się odczytać tokenu zakupu.';
      _hasActiveEntitlement = false;
      return;
    }

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-central2');
      final callable = functions.httpsCallable('verifyAndroidSubscription');
      final result = await callable.call(<String, dynamic>{
        'packageName': _androidPackageName,
        'purchaseToken': purchaseToken,
      });

      final data = result.data;
      final hasActiveEntitlement =
          (data is Map && data['hasActiveEntitlement'] == true);

      _hasActiveEntitlement = hasActiveEntitlement;
      _errorMessage = hasActiveEntitlement
          ? null
          : 'Subskrypcja nie została potwierdzona po stronie serwera.';
    } catch (e) {
      _hasActiveEntitlement = false;
      _errorMessage =
          'Nie udało się potwierdzić zakupu po stronie serwera: $e';
    }
  }

  String? _extractPurchaseToken(PurchaseDetails purchase) {
    return purchase.verificationData.serverVerificationData;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
