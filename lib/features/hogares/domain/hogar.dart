import 'package:cloud_firestore/cloud_firestore.dart';

class Hogar {
  final String id;
  final String nombre;
  final String creadoPor;
  final Map<String, String> miembros; // uid → "owner" | "member"
  final List<String> miembrosIds;
  final int productosActivos;
  final DateTime createdAt;

  const Hogar({
    required this.id,
    required this.nombre,
    required this.creadoPor,
    required this.miembros,
    required this.miembrosIds,
    required this.productosActivos,
    required this.createdAt,
  });

  bool esOwner(String uid) => miembros[uid] == 'owner';
  bool esMiembro(String uid) => miembros.containsKey(uid);

  factory Hogar.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    final rawMiembros = data['miembros'] as Map<String, dynamic>? ?? {};
    return Hogar(
      id: snap.id,
      nombre: data['nombre'] as String? ?? '',
      creadoPor: data['creadoPor'] as String? ?? '',
      miembros: rawMiembros.map((k, v) => MapEntry(k, v as String)),
      miembrosIds: List<String>.from(data['miembrosIds'] as List? ?? []),
      productosActivos: data['productosActivos'] as int? ?? 0,
      createdAt: data['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'creadoPor': creadoPor,
        'miembros': miembros,
        'miembrosIds': miembrosIds,
        'productosActivos': productosActivos,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class Invitacion {
  final String codigo;
  final String creadoPor;
  final DateTime expiraEn;
  final String? usadoPor;

  const Invitacion({
    required this.codigo,
    required this.creadoPor,
    required this.expiraEn,
    this.usadoPor,
  });

  bool get estaVigente =>
      usadoPor == null && DateTime.now().isBefore(expiraEn);

  factory Invitacion.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return Invitacion(
      codigo: data['codigo'] as String? ?? snap.id,
      creadoPor: data['creadoPor'] as String? ?? '',
      expiraEn: data['expiraEn'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['expiraEn'] as int)
          : (data['expiraEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usadoPor: data['usadoPor'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'creadoPor': creadoPor,
        'expiraEn': expiraEn.millisecondsSinceEpoch,
        'usadoPor': usadoPor,
      };
}
