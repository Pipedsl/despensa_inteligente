// lib/core/plan_config.dart

/// Límite de productos activos en la despensa por plan.
const Map<String, int> kPlanMaxProductos = {
  'free': 30,
  'pro': 200,
};

/// Retorna el límite de productos para el plan dado.
/// Usa 30 como fallback si el plan no se reconoce.
int maxProductosParaPlan(String plan) => kPlanMaxProductos[plan] ?? 30;
