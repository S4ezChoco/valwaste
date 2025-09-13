import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_auth_service.dart';
import 'firebase_notification_service.dart';

class EnhancedNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize the enhanced notification service
  static Future<void> initialize() async {
    try {
      // Request permission for push notifications
      await _requestNotificationPermission();

      // Configure Firebase messaging
      await _configureFirebaseMessaging();

      // Set up message handlers
      _setupMessageHandlers();

      print('Enhanced Notification Service initialized successfully');
    } catch (e) {
      print('Error initializing Enhanced Notification Service: $e');
    }
  }


  // Request notification permission
  static Future<void> _requestNotificationPermission() async {
    // Request permission for Firebase messaging
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  // Configure Firebase messaging
  static Future<void> _configureFirebaseMessaging() async {
    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Save token to user document
    if (FirebaseAuthService.currentUser != null && token != null) {
      await _firestore
          .collection('users')
          .doc(FirebaseAuthService.currentUser!.id)
          .update({
            'fcm_token': token,
            'notification_enabled': true,
            'last_token_update': FieldValue.serverTimestamp(),
          });
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      if (FirebaseAuthService.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(FirebaseAuthService.currentUser!.id)
            .update({
              'fcm_token': newToken,
              'last_token_update': FieldValue.serverTimestamp(),
            });
      }
    });
  }

  // Set up message handlers
  static void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // Handle foreground message
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    // In a real app, you would show a local notification here
    // For now, we'll just log the message
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    _handleNotificationNavigation(message.data.toString());
  }

  // Handle notification navigation
  static void _handleNotificationNavigation(String? payload) {
    if (payload == null) return;

    // Parse payload and navigate accordingly
    // This would be implemented based on your app's navigation structure
    print('Handling notification navigation with payload: $payload');
  }

  // Send push notification to specific user
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final fcmToken = userData['fcm_token'] as String?;
      final notificationEnabled =
          userData['notification_enabled'] as bool? ?? true;

      if (fcmToken == null || !notificationEnabled) return false;

      // Create notification in Firestore
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });

      // Send push notification (in a real app, you would use Firebase Admin SDK or a cloud function)
      // For now, we'll just create the notification in Firestore

      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send notification to multiple users
  static Future<void> sendNotificationToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      await sendNotificationToUser(
        userId: userId,
        title: title,
        message: message,
        type: type,
        data: data,
      );
    }
  }

  // Send notification to all users in a barangay
  static Future<void> sendNotificationToBarangay({
    required String barangay,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('barangay', isEqualTo: barangay)
          .where('notification_enabled', isEqualTo: true)
          .get();

      final userIds = querySnapshot.docs.map((doc) => doc.id).toList();

      await sendNotificationToMultipleUsers(
        userIds: userIds,
        title: title,
        message: message,
        type: type,
        data: data,
      );
    } catch (e) {
      print('Error sending notification to barangay: $e');
    }
  }

  // Get real-time notifications stream
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

  // Get unread notification count stream
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

  // Schedule notification reminder (simplified version)
  static Future<void> scheduleNotificationReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // In a real app, you would schedule a local notification here
      // For now, we'll just create a notification in Firestore
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        await _firestore.collection('notifications').add({
          'user_id': currentUser.id,
          'title': title,
          'message': body,
          'type': 'reminder',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'scheduled_time': Timestamp.fromDate(scheduledTime),
          'data': payload ?? {},
        });
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Cancel all scheduled notifications (simplified version)
  static Future<void> cancelAllScheduledNotifications() async {
    try {
      // In a real app, you would cancel local notifications here
      // For now, we'll just mark scheduled notifications as cancelled
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('notifications')
            .where('user_id', isEqualTo: currentUser.id)
            .where('type', isEqualTo: 'reminder')
            .where('is_read', isEqualTo: false)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'cancelled': true});
          }
        });
      }
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }

  // Update user notification preferences
  static Future<bool> updateNotificationPreferences({
    required bool enabled,
    required bool collectionReminders,
    required bool statusUpdates,
    required bool announcements,
    required int reminderHours,
  }) async {
    try {
      if (FirebaseAuthService.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(FirebaseAuthService.currentUser!.id)
          .update({
            'notification_enabled': enabled,
            'collection_reminders': collectionReminders,
            'status_updates': statusUpdates,
            'announcements': announcements,
            'reminder_hours': reminderHours,
            'preferences_updated_at': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('Error updating notification preferences: $e');
      return false;
    }
  }

  // Get user notification preferences
  static Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      if (FirebaseAuthService.currentUser == null) return {};

      final doc = await _firestore
          .collection('users')
          .doc(FirebaseAuthService.currentUser!.id)
          .get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      return {
        'enabled': data['notification_enabled'] ?? true,
        'collection_reminders': data['collection_reminders'] ?? true,
        'status_updates': data['status_updates'] ?? true,
        'announcements': data['announcements'] ?? true,
        'reminder_hours': data['reminder_hours'] ?? 2,
      };
    } catch (e) {
      print('Error getting notification preferences: $e');
      return {};
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background message processing
}
