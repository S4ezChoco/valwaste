import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get active announcements
  static Stream<QuerySnapshot> getActiveAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Get archived announcements
  static Stream<QuerySnapshot> getArchivedAnnouncements() {
    return _firestore
        .collection('archived_announcements')
        .orderBy('archivedAt', descending: true)
        .limit(50)
        .snapshots();
  }
  
  // Mark announcement as read
  static Future<void> markAsRead(String announcementId, String userId) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcementId)
          .collection('readBy')
          .doc(userId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });
    } catch (e) {
      print('Error marking announcement as read: $e');
    }
  }
  
  // Check if announcement is read by user
  static Future<bool> isRead(String announcementId, String userId) async {
    try {
      final doc = await _firestore
          .collection('announcements')
          .doc(announcementId)
          .collection('readBy')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking read status: $e');
      return false;
    }
  }
}
