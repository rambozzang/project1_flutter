import 'dart:async';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 스토어 상품 ID(Google Play / App Store 콘솔에 실제로 등록해야 함).
class PremiumProductIds {
  static const String monthly = 'skysnap_premium_monthly';
  static const String yearly = 'skysnap_premium_yearly';

  static const List<String> all = [monthly, yearly];
}

/// 프리미엄 구독 상태를 관리하는 싱글톤.
/// - 스토어에서 상품/구매 내역을 조회하고, 구매/복원을 처리한다.
/// - 구매가 확정되면 서버(/cust/premium/sync)에 동기화해 premiumYn/만료일을 갱신한다.
class SubscriptionService extends GetxService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;

  final RxBool available = false.obs;
  final RxList<ProductDetails> products = <ProductDetails>[].obs;
  final RxBool isSubscribed = false.obs;
  final RxBool restoring = false.obs;
  final RxBool purchasing = false.obs;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final bool isAvailable = await _iap.isAvailable();
    available.value = isAvailable;
    lo.g('IAP available=$isAvailable');
    if (!isAvailable) return;

    _sub = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _sub?.cancel(),
      onError: (e) => lo.g('IAP stream error: $e'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse res =
          await _iap.queryProductDetails(PremiumProductIds.all.toSet());
      if (res.notFoundIDs.isNotEmpty) {
        lo.g('IAP not found IDs: ${res.notFoundIDs}');
      }
      products.assignAll(res.productDetails);
      lo.g('IAP products loaded: ${products.map((p) => p.id).toList()}');
    } catch (e) {
      lo.g('IAP loadProducts error: $e');
    }
  }

  ProductDetails? productById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> buy(String productId) async {
    final ProductDetails? product = productById(productId);
    if (product == null) {
      Utils.alert('구독 상품을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
      return;
    }
    purchasing.value = true;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      lo.g('IAP buy error: $e');
      Utils.alert('구매를 시작하지 못했습니다: $e');
    } finally {
      purchasing.value = false;
    }
  }

  Future<void> restore() async {
    restoring.value = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      lo.g('IAP restore error: $e');
      Utils.alert('복원에 실패했습니다: $e');
    } finally {
      restoring.value = false;
    }
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> detailsList) async {
    for (final PurchaseDetails details in detailsList) {
      lo.g('IAP purchase update: ${details.productID} status=${details.status}');
      if (details.status == PurchaseStatus.pending) {
        purchasing.value = true;
      } else {
        if (details.status == PurchaseStatus.error) {
          lo.g('IAP purchase error: ${details.error}');
          purchasing.value = false;
        } else if (details.status == PurchaseStatus.purchased ||
            details.status == PurchaseStatus.restored) {
          await _grantPremium(details);
        }
        if (details.pendingCompletePurchase) {
          await _iap.completePurchase(details);
        }
      }
    }
  }

  /// 구매 확정 후 서버에 동기화하고 로컬 프리미엄 상태를 갱신한다.
  Future<void> _grantPremium(PurchaseDetails details) async {
    purchasing.value = false;
    try {
      final DateTime expire = DateTime.now().add(const Duration(days: 30));
      final res = await CustRepo().syncPremium(
        productId: details.productID,
        orderId: details.purchaseID ?? details.productID,
        expireDate: expire,
        active: true,
      );
      if (res.code == '00') {
        AuthCntr.to.applyPremium();
        isSubscribed.value = true;
        Utils.alert('프리미엄 구독이 활성화되었습니다!');
      } else {
        lo.g('IAP sync failed: ${res.msg}');
      }
    } catch (e) {
      lo.g('IAP grant error: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
