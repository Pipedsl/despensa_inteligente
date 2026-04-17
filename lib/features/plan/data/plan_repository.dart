import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:despensa_inteligente/features/plan/domain/plan_config.dart';

class PlanRepository {
  final FirebaseFirestore _firestore;

  PlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<PlanConfig> getPlan(String planId) async {
    final snap = await _firestore.doc('planes_config/$planId').get();
    if (!snap.exists) return PlanConfig.free;
    return PlanConfig.fromMap(snap.data()!, planId);
  }
}
