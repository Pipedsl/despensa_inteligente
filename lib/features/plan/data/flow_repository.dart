import 'package:cloud_functions/cloud_functions.dart';

abstract interface class FlowCallable {
  Future<Map<String, dynamic>> call(Map<String, dynamic> data);
}

class _FirebaseFlowCallable implements FlowCallable {
  final HttpsCallable _fn;
  _FirebaseFlowCallable(this._fn);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    final result = await _fn.call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }
}

sealed class FlowResult {}

class FlowUrlOk extends FlowResult {
  final String url;
  final String token;
  FlowUrlOk({required this.url, required this.token});
}

class FlowError extends FlowResult {
  final String message;
  FlowError(this.message);
}

class FlowRepository {
  final FlowCallable crearSuscripcionFn;

  FlowRepository({required this.crearSuscripcionFn});

  factory FlowRepository.firebase() {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    return FlowRepository(
      crearSuscripcionFn: _FirebaseFlowCallable(
        functions.httpsCallable('crearSuscripcionFlow'),
      ),
    );
  }

  Future<FlowResult> crearSuscripcion() async {
    try {
      final response = await crearSuscripcionFn.call(<String, dynamic>{});
      final url = response['url'] as String?;
      final token = response['token'] as String?;
      if (url == null || url.isEmpty) {
        return FlowError('No se recibió URL de registro de tarjeta');
      }
      return FlowUrlOk(url: url, token: token ?? '');
    } catch (e) {
      return FlowError(e.toString());
    }
  }
}
