import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_service.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      isRead: data['is_read'] ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FirebaseNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's notifications
  static Future<List<NotificationModel>> getUserNotifications() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: FirebaseAuthService.currentUser!.id)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return;
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: FirebaseAuthService.currentUser!.id)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return 0;
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: FirebaseAuthService.currentUser!.id)
          .where('is_read', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Create a new notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {'totalNotifications': 0, 'unreadNotifications': 0};
      }

      final notifications = await getUserNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;

      return {
        'totalNotifications': notifications.length,
        'unreadNotifications': unreadCount,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {'totalNotifications': 0, 'unreadNotifications': 0};
    }
  }

  // Stream for real-time notifications
  static Stream<List<NotificationModel>> getUserNotificationsStream() {
    if (FirebaseAuthService.currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: FirebaseAuthService.currentUser!.id)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream for real-time unread count
  static Stream<int> getUnreadNotificationCountStream() {
    if (FirebaseAuthService.currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: FirebaseAuthService.currentUser!.id)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
