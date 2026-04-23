class PlanConfig {
  final String id;
  final int maxRecetasMes;
  final String modeloReceta;
  final int maxHogares;
  final int maxMiembrosHogar;
  final int maxProductos;
  final int historialLimite;
  final String? stripePriceId;

  const PlanConfig({
    required this.id,
    required this.maxRecetasMes,
    required this.modeloReceta,
    required this.maxHogares,
    required this.maxMiembrosHogar,
    required this.maxProductos,
    required this.historialLimite,
    this.stripePriceId,
  });

  bool get esIlimitadoMiembros => maxMiembrosHogar == -1;
  bool get historialCompleto => historialLimite == -1;

  factory PlanConfig.fromMap(Map<String, dynamic> map, String id) {
    return PlanConfig(
      id: id,
      maxRecetasMes: (map['maxRecetasMes'] as num).toInt(),
      modeloReceta: map['modeloReceta'] as String,
      maxHogares: (map['maxHogares'] as num).toInt(),
      maxMiembrosHogar: (map['maxMiembrosHogar'] as num).toInt(),
      maxProductos: (map['maxProductos'] as num).toInt(),
      historialLimite: (map['historialLimite'] as num).toInt(),
      stripePriceId: map['stripePriceId'] as String?,
    );
  }

  static const PlanConfig free = PlanConfig(
    id: 'free',
    maxRecetasMes: 3,
    modeloReceta: 'gemini-2.0-flash',
    maxHogares: 1,
    maxMiembrosHogar: 4,
    maxProductos: 30,
    historialLimite: 10,
  );
}
