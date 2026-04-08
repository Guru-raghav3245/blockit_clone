import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/freedom_session.dart';

class CloudSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Push all local data to the cloud (Overwrites cloud with the merged truth)
  static Future<void> pushToCloud(
    String uid,
    int totalSessions,
    int totalMinutes,
    int parachutesUsed,
    List<FreedomSession> sessions,
  ) async {
    try {
      await _db.collection('users').doc(uid).set({
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'parachutesUsed': parachutesUsed,
        'sessionsList': sessions.map((s) => s.toJson()).toList(),
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error pushing to cloud: $e");
    }
  }

  // 2. Fetch the user's data from the cloud
  static Future<Map<String, dynamic>?> pullFromCloud(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print("Error pulling from cloud: $e");
    }
    return null;
  }
}