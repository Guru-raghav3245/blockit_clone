import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/freedom_session.dart';
import '../models/reels_free_time_record.dart';

class CloudSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> pushToCloud(
    String uid,
    int totalSessions,
    int totalMinutes,
    int parachutesUsed,
    List<FreedomSession> sessions,
    List<ReelsFreeTimeRecord> reelsFreeRecords,
  ) async {
    try {
      await _db.collection('users').doc(uid).set({
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'parachutesUsed': parachutesUsed,
        'sessionsList': sessions.map((s) => s.toJson()).toList(),
        'reelsFreeTimeList': reelsFreeRecords.map((r) => r.toJson()).toList(), // Uploads duration records matrix directly to Firebase doc
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error pushing to cloud endpoint maps: $e");
    }
  }

  static Future<Map<String, dynamic>?> pullFromCloud(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print("Error pulling from cloud database endpoints: $e");
    }
    return null;
  }
}