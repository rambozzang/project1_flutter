// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SubscriptionService {
//   static const String _kSubscriptionId = 'your_subscription_id_here';
//   static const String _kSubscriptionStatusKey = 'subscription_status';
  
//   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
//   late StreamSubscription<List<PurchaseDetails>> _subscription;
//   bool _isSubscribed = false;

//   final _subscriptionStatusController = StreamController<bool>.broadcast();

//   Stream<bool> get subscriptionStatus => _subscriptionStatusController.stream;

//   SubscriptionService() {
//     _loadSubscriptionStatus();
//   }

//   Future<void> initialize() async {
//     final bool available = await _inAppPurchase.isAvailable();
//     if (!available) {
//       // The store cannot be reached or accessed. Handle this case.
//       debugPrint('In-app purchases not available');
//       return;
//     }

//     // Set up listener for purchase updates
//     _subscription = _inAppPurchase.purchaseStream.listen(
//       _handlePurchaseUpdate,
//       onDone: _updateStreamOnDone,
//       onError: _updateStreamOnError,
//     );

//     // Load the subscription product
//     await _getProductDetails();
//   }

//   Future<void> _getProductDetails() async {
//     Set<String> _kIds = <String>{_kSubscriptionId};
//     ProductDetailsResponse response =
//         await _inAppPurchase.queryProductDetails(_kIds);
    
//     if (response.notFoundIDs.isNotEmpty) {
//       // Handle the error: Subscription product not found
//       debugPrint('Subscription product not found');
//     }
    
//     List<ProductDetails> products = response.productDetails;
//     if (products.isNotEmpty) {
//       // You can use the product details here, e.g., to display the price
//       debugPrint('Subscription price: ${products.first.price}');
//     }
//   }

//   void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
//     purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
//       if (purchaseDetails.status == PurchaseStatus.pending) {
//         // Show a dialog that the purchase is pending
//         debugPrint('Purchase pending');
//       } else {
//         if (purchaseDetails.status == PurchaseStatus.error) {
//           // Handle the error
//           debugPrint('Error purchasing: ${purchaseDetails.error}');
//         } else if (purchaseDetails.status == PurchaseStatus.purchased ||
//             purchaseDetails.status == PurchaseStatus.restored) {
//           // Grant access to the subscription content
//           await _verifyPurchase(purchaseDetails);
//         }
//         if (purchaseDetails.pendingCompletePurchase) {
//           await _inAppPurchase.completePurchase(purchaseDetails);
//         }
//       }
//     });
//   }

//   Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
//     // Here you should implement your own purchase verification logic
//     // This might involve sending the purchase details to your server
//     // For this example, we'll just consider it verified
//     debugPrint('Purchase verified');
    
//     _isSubscribed = true;
//     _subscriptionStatusController.add(_isSubscribed);
//     await _saveSubscriptionStatus();
//   }

//   void _updateStreamOnDone() {
//     _subscription.cancel();
//   }

//   void _updateStreamOnError(dynamic error) {
//     // Handle any errors from the subscription stream
//     debugPrint('Error in subscription stream: $error');
//   }

//   Future<void> subscribe() async {
//     final ProductDetailsResponse response =
//         await _inAppPurchase.queryProductDetails({_kSubscriptionId});
    
//     if (response.productDetails.isEmpty) {
//       // Handle the error: subscription product not found
//       debugPrint('Subscription product not found');
//       return;
//     }

//     final ProductDetails product = response.productDetails.first;
//     final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
//     // Start the subscription purchase
//     try {
//       final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
//       debugPrint('Purchase started: $success');
//     } catch (e) {
//       debugPrint('Error starting purchase: $e');
//     }
//   }

//   Future<void> restorePurchases() async {
//     await _inAppPurchase.restorePurchases();
//   }

//   Future<void> _loadSubscriptionStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     _isSubscribed = prefs.getBool(_kSubscriptionStatusKey) ?? false;
//     _subscriptionStatusController.add(_isSubscribed);
//   }

//   Future<void> _saveSubscriptionStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_kSubscriptionStatusKey, _isSubscribed);
//   }

//   bool get isSubscribed => _isSubscribed;

//   void dispose() {
//     _subscription.cancel();
//     _subscriptionStatusController.close();
//   }
// }