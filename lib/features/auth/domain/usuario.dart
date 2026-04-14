import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String plan; // "free" | "pro"
  final String? hogarActivo;
  final DateTime createdAt;

  const Usuario({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.plan,
    this.hogarActivo,
    required this.createdAt,
  });

  factory Usuario.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return Usuario(
      uid: snap.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      plan: data['plan'] as String? ?? 'free',
      hogarActivo: data['hogarActivo'] as String?,
      createdAt: data['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'plan': plan,
        'hogarActivo': hogarActivo,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Usuario copyWith({String? hogarActivo}) => Usuario(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        plan: plan,
        hogarActivo: hogarActivo ?? this.hogarActivo,
        createdAt: createdAt,
      );
}
