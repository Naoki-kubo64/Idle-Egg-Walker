import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  bool _isInitialized = false;

  // Production API Key
  final String _apiKey = 'goog_OaxsRvWWsMOvlQHobjeYeuxRgvO';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _isInitialized = true;
    } catch (e) {
      // debugPrint('Failed to init RevenueCat: $e');
    }
  }

  /// Check if user has 'egg_walker_pro' entitlement
  Future<bool> isProUser() async {
    try {
      if (!_isInitialized) await init();
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['egg_walker_pro']?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Show RevenueCat Paywall
  Future<void> presentPaywall() async {
    if (!_isInitialized) await init();
    try {
      await RevenueCatUI.presentPaywallIfNeeded("egg_walker_pro");
    } catch (e) {
      // Fallback or log error
      // debugPrint('Paywall error: $e');
    }
  }

  /// Show Customer Center
  Future<void> presentCustomerCenter() async {
    if (!_isInitialized) await init();
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      // debugPrint('Customer Center error: $e');
    }
  }

  /// Get current offerings (products configured in RevenueCat)
  Future<Offerings?> getOfferings() async {
    try {
      if (!_isInitialized) await init();
      return await Purchases.getOfferings();
    } on PlatformException catch (_) {
      // debugPrint('Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  /// Returns CustomerInfo if successful, null if failed/cancelled
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      if (!_isInitialized) await init();
      return (await Purchases.purchasePackage(package)).customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        // debugPrint('Purchase error: $e');
      }
      return null;
    }
  }

  /// Restore purchases (mostly for non-consumables, but good practice)
  Future<CustomerInfo?> restorePurchases() async {
    try {
      if (!_isInitialized) await init();
      return await Purchases.restorePurchases();
    } on PlatformException catch (_) {
      return null;
    }
  }
}
