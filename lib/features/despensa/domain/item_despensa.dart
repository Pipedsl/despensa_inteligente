import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoVencimiento { sinFecha, vencido, urgente, porVencer, ok }

const List<String> kUnidades = [
  'unidades',
  'kg',
  'g',
  'L',
  'mL',
  'paquetes',
  'cajas',
];

class ItemDespensa {
  final String id;
  final String nombre;
  final double cantidad;
  final String unidad;
  final DateTime? fechaVencimiento;
  final DateTime? fechaCompra;
  final double? precio;
  final String moneda;
  final String? tienda;
  final double? cantidadComprada;
  final String agregadoPor;
  final String? notas;
  final String estado; // "activo" | "consumido" | "vencido"
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemDespensa({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    this.fechaVencimiento,
    this.fechaCompra,
    this.precio,
    this.moneda = 'CLP',
    this.tienda,
    this.cantidadComprada,
    required this.agregadoPor,
    this.notas,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  int? get diasParaVencer {
    if (fechaVencimiento == null) return null;
    final hoy = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final vence = DateTime(
      fechaVencimiento!.year,
      fechaVencimiento!.month,
      fechaVencimiento!.day,
    );
    return vence.difference(hoy).inDays;
  }

  EstadoVencimiento get estadoVencimiento {
    final dias = diasParaVencer;
    if (dias == null) return EstadoVencimiento.sinFecha;
    if (dias < 0) return EstadoVencimiento.vencido;
    if (dias < 3) return EstadoVencimiento.urgente;
    if (dias < 7) return EstadoVencimiento.porVencer;
    return EstadoVencimiento.ok;
  }

  bool get venceProximamente {
    final dias = diasParaVencer;
    return dias != null && dias <= 1;
  }

  factory ItemDespensa.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ItemDespensa(
      id: snap.id,
      nombre: data['nombre'] as String? ?? '',
      cantidad: (data['cantidad'] as num?)?.toDouble() ?? 1.0,
      unidad: data['unidad'] as String? ?? 'unidades',
      fechaVencimiento: parseDate(data['fechaVencimiento']),
      fechaCompra: parseDate(data['fechaCompra']),
      precio: (data['precio'] as num?)?.toDouble(),
      moneda: data['moneda'] as String? ?? 'CLP',
      tienda: data['tienda'] as String?,
      cantidadComprada: (data['cantidadComprada'] as num?)?.toDouble(),
      agregadoPor: data['agregadoPor'] as String? ?? '',
      notas: data['notas'] as String?,
      estado: data['estado'] as String? ?? 'activo',
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'cantidad': cantidad,
    'unidad': unidad,
    if (fechaVencimiento != null)
      'fechaVencimiento': fechaVencimiento!.millisecondsSinceEpoch,
    if (fechaCompra != null)
      'fechaCompra': fechaCompra!.millisecondsSinceEpoch,
    if (precio != null) 'precio': precio,
    'moneda': moneda,
    if (tienda != null) 'tienda': tienda,
    if (cantidadComprada != null) 'cantidadComprada': cantidadComprada,
    'agregadoPor': agregadoPor,
    if (notas != null) 'notas': notas,
    'estado': estado,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  ItemDespensa copyWith({
    String? nombre,
    double? cantidad,
    String? unidad,
    DateTime? fechaVencimiento,
    DateTime? fechaCompra,
    double? precio,
    String? tienda,
    double? cantidadComprada,
    String? notas,
    String? estado,
  }) {
    return ItemDespensa(
      id: id,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      precio: precio ?? this.precio,
      moneda: moneda,
      tienda: tienda ?? this.tienda,
      cantidadComprada: cantidadComprada ?? this.cantidadComprada,
      agregadoPor: agregadoPor,
      notas: notas ?? this.notas,
      estado: estado ?? this.estado,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
