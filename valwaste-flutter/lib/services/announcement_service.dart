import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get active announcements in real-time
  Stream<List<Announcement>> getActiveAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          print('AnnouncementService: Got ${snapshot.docs.length} documents');
          final now = DateTime.now();

          final announcements = snapshot.docs
              .map((doc) {
                try {
                  return Announcement.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing announcement ${doc.id}: $e');
                  return null;
                }
              })
              .where((announcement) => announcement != null)
              .cast<Announcement>()
              .where((announcement) {
                // Only show non-expired announcements
                final isNotExpired = !announcement.isExpired;
                print(
                  'Announcement ${announcement.id}: expired=${announcement.isExpired}, message="${announcement.message}"',
                );
                return isNotExpired;
              })
              .toList();

          // Sort by creation date (newest first)
          announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print(
            'AnnouncementService: Returning ${announcements.length} active announcements',
          );
          return announcements;
        });
  }

  // Get latest announcement for notifications
  Future<Announcement?> getLatestAnnouncement() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final announcement = Announcement.fromFirestore(snapshot.docs.first);
        // Check if not expired
        if (!announcement.isExpired) {
          return announcement;
        }
      }
      return null;
    } catch (error) {
      print('Error getting latest announcement: $error');
      return null;
    }
  }

  // Get announcements for a specific date range
  Future<List<Announcement>> getAnnouncementsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => !announcement.isExpired)
          .toList();
    } catch (error) {
      print('Error getting announcements for date range: $error');
      return [];
    }
  }

  // Get announcement count
  Future<int> getActiveAnnouncementCount() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .get();

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => !announcement.isExpired)
          .length;
    } catch (error) {
      print('Error getting announcement count: $error');
      return 0;
    }
  }

  // Check if there are new announcements since last check
  Future<bool> hasNewAnnouncements(DateTime lastCheckTime) async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastCheckTime))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error checking for new announcements: $error');
      return false;
    }
  }
}
