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
  final String? barcode;

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
    this.barcode,
  });

  int? get diasParaVencer {
    if (fechaVencimiento == null) return null;
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
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
      barcode: data['barcode'] as String?,
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
    if (barcode != null) 'barcode': barcode,
  };

  static const Object _unset = Object();

  ItemDespensa copyWith({
    String? nombre,
    double? cantidad,
    String? unidad,
    Object? fechaVencimiento = _unset,
    Object? fechaCompra = _unset,
    Object? precio = _unset,
    Object? tienda = _unset,
    Object? cantidadComprada = _unset,
    Object? notas = _unset,
    String? estado,
    Object? barcode = _unset,
  }) {
    return ItemDespensa(
      id: id,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      fechaVencimiento: fechaVencimiento == _unset
          ? this.fechaVencimiento
          : fechaVencimiento as DateTime?,
      fechaCompra: fechaCompra == _unset
          ? this.fechaCompra
          : fechaCompra as DateTime?,
      precio: precio == _unset ? this.precio : precio as double?,
      moneda: moneda,
      tienda: tienda == _unset ? this.tienda : tienda as String?,
      cantidadComprada: cantidadComprada == _unset
          ? this.cantidadComprada
          : cantidadComprada as double?,
      agregadoPor: agregadoPor,
      notas: notas == _unset ? this.notas : notas as String?,
      estado: estado ?? this.estado,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      barcode: barcode == _unset ? this.barcode : barcode as String?,
    );
  }
}
