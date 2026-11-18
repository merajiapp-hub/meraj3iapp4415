import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/countdown_event.dart';

class CountdownService {
  CountdownService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('countdown_events');

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _firestore.collection('app_settings').doc('countdown_config');

  Stream<List<CountdownEvent>> streamActiveEvents() {
    return _collection
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(CountdownEvent.fromFirestore)
              .where((ev) => ev.isActive && !ev.shouldHide)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
          return list;
        });
  }

  Stream<bool> streamCountdownEnabled() {
    return _configDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return true;
      return snapshot.data()?['countdown_enabled'] != false;
    });
  }
}
