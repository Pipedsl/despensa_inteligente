import 'package:cloud_functions/cloud_functions.dart';

abstract interface class CheckoutCallable {
  Future<Map<String, dynamic>> call(Map<String, dynamic> data);
}

class _FirebaseCheckoutCallable implements CheckoutCallable {
  final HttpsCallable _fn;
  _FirebaseCheckoutCallable(this._fn);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    final result = await _fn.call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }
}

sealed class CheckoutResult {}

class CheckoutUrlOk extends CheckoutResult {
  final String url;
  CheckoutUrlOk(this.url);
}

class CheckoutError extends CheckoutResult {
  final String message;
  CheckoutError(this.message);
}

class StripeRepository {
  final CheckoutCallable checkoutFn;

  StripeRepository({required this.checkoutFn});

  factory StripeRepository.firebase() {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    return StripeRepository(
      checkoutFn: _FirebaseCheckoutCallable(
        functions.httpsCallable('crearCheckoutSession'),
      ),
    );
  }

  Future<CheckoutResult> crearCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await checkoutFn.call({
        'priceId': priceId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      });
      final url = response['url'] as String?;
      if (url == null || url.isEmpty) {
        return CheckoutError('No se recibió URL de checkout');
      }
      return CheckoutUrlOk(url);
    } catch (e) {
      return CheckoutError(e.toString());
    }
  }
}
