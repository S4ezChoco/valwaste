import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_collection.dart';
import '../models/user.dart';
import 'firebase_auth_service.dart';
import 'enhanced_notification_service.dart';

class AdvancedSchedulingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Time slots for different waste types
  static const Map<String, List<String>> _timeSlots = {
    'general': [
      '06:00-08:00',
      '08:00-10:00',
      '10:00-12:00',
      '14:00-16:00',
      '16:00-18:00',
    ],
    'recyclable': ['06:00-08:00', '08:00-10:00', '10:00-12:00'],
    'organic': ['06:00-08:00', '08:00-10:00', '18:00-20:00'],
    'hazardous': ['08:00-10:00', '10:00-12:00', '14:00-16:00'],
    'electronic': ['08:00-10:00', '10:00-12:00', '14:00-16:00'],
  };

  // Priority levels for different waste types
  static const Map<String, int> _wasteTypePriority = {
    'hazardous': 1,
    'electronic': 2,
    'organic': 3,
    'recyclable': 4,
    'general': 5,
  };

  // Get available time slots for a specific date and waste type
  static Future<List<String>> getAvailableTimeSlots({
    required DateTime date,
    required WasteType wasteType,
    required String barangay,
  }) async {
    try {
      final wasteTypeString = wasteType.toString().split('.').last;
      final baseTimeSlots =
          _timeSlots[wasteTypeString] ?? _timeSlots['general']!;

      // Get existing collections for the date and barangay
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('collections')
          .where('scheduled_date', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduled_date', isLessThan: endOfDay)
          .where('status', whereIn: ['scheduled', 'inProgress'])
          .get();

      // Count collections per time slot
      final Map<String, int> slotCounts = {};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final scheduledDate = (data['scheduled_date'] as Timestamp).toDate();
        final hour = scheduledDate.hour;
        final timeSlot = _getTimeSlotForHour(hour);

        if (timeSlot != null) {
          slotCounts[timeSlot] = (slotCounts[timeSlot] ?? 0) + 1;
        }
      }

      // Filter available slots (max 10 collections per slot)
      final availableSlots = <String>[];
      for (final slot in baseTimeSlots) {
        final count = slotCounts[slot] ?? 0;
        if (count < 10) {
          availableSlots.add(slot);
        }
      }

      return availableSlots;
    } catch (e) {
      print('Error getting available time slots: $e');
      return _timeSlots['general']!;
    }
  }

  // Get time slot for a specific hour
  static String? _getTimeSlotForHour(int hour) {
    if (hour >= 6 && hour < 8) return '06:00-08:00';
    if (hour >= 8 && hour < 10) return '08:00-10:00';
    if (hour >= 10 && hour < 12) return '10:00-12:00';
    if (hour >= 14 && hour < 16) return '14:00-16:00';
    if (hour >= 16 && hour < 18) return '16:00-18:00';
    if (hour >= 18 && hour < 20) return '18:00-20:00';
    return null;
  }

  // Get hour from time slot string
  static int _getHourFromTimeSlot(String timeSlot) {
    final parts = timeSlot.split('-');
    final startTime = parts[0];
    final hour = int.parse(startTime.split(':')[0]);
    return hour;
  }

  // Schedule collection with advanced features
  static Future<Map<String, dynamic>> scheduleCollection({
    required WasteType wasteType,
    required double quantity,
    required String unit,
    required String description,
    required String address,
    required String barangay,
    double? latitude,
    double? longitude,
    String? notes,
    bool isUrgent = false,
    DateTime? preferredDate,
    String? preferredTimeSlot,
    List<String>? alternativeDates,
    String? priority,
    String? category,
  }) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please login first.',
        };
      }

      // Set default values if not provided
      DateTime scheduledDate =
          preferredDate ?? DateTime.now().add(const Duration(days: 1));
      String scheduledTimeSlot = preferredTimeSlot ?? '08:00-10:00';

      // Check if preferred time slot is available (only if both date and time are provided)
      if (preferredDate != null && preferredTimeSlot != null) {
        final availableSlots = await getAvailableTimeSlots(
          date: preferredDate,
          wasteType: wasteType,
          barangay: barangay,
        );

        if (!availableSlots.contains(preferredTimeSlot)) {
          // Try alternative dates
          if (alternativeDates != null && alternativeDates.isNotEmpty) {
            for (final altDateStr in alternativeDates) {
              final altDate = DateTime.parse(altDateStr);
              final altSlots = await getAvailableTimeSlots(
                date: altDate,
                wasteType: wasteType,
                barangay: barangay,
              );

              if (altSlots.isNotEmpty) {
                scheduledDate = altDate;
                scheduledTimeSlot = altSlots.first;
                break;
              }
            }
          } else {
            // Use first available slot on preferred date
            if (availableSlots.isNotEmpty) {
              scheduledTimeSlot = availableSlots.first;
            } else {
              // Find next available date
              DateTime nextDate = preferredDate.add(const Duration(days: 1));
              for (int i = 0; i < 7; i++) {
                final slots = await getAvailableTimeSlots(
                  date: nextDate,
                  wasteType: wasteType,
                  barangay: barangay,
                );

                if (slots.isNotEmpty) {
                  scheduledDate = nextDate;
                  scheduledTimeSlot = slots.first;
                  break;
                }
                nextDate = nextDate.add(const Duration(days: 1));
              }
            }
          }
        }
      }

      // Set the exact scheduled time
      final hour = _getHourFromTimeSlot(scheduledTimeSlot);
      final finalScheduledDate = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        hour,
        0,
      );

      // Priority logic: User-selected priority takes precedence, then urgency, then waste type
      int finalPriority;
      String finalPriorityText;
      
      if (priority != null) {
        // User explicitly selected a priority - use it
        finalPriorityText = priority;
        switch (priority.toLowerCase()) {
          case 'high':
            finalPriority = 1;
            break;
          case 'medium':
            finalPriority = 3;
            break;
          case 'low':
            finalPriority = 5;
            break;
          default:
            finalPriority = 3;
            finalPriorityText = 'Medium';
        }
      } else {
        // No user priority - calculate based on urgency and waste type
        final wasteTypeString = wasteType.toString().split('.').last;
        final basePriority = _wasteTypePriority[wasteTypeString] ?? 5;
        
        if (isUrgent) {
          finalPriority = 1; // Urgent always gets highest priority
          finalPriorityText = 'High';
        } else {
          finalPriority = basePriority;
          finalPriorityText = basePriority <= 2 ? 'High' : (basePriority <= 3 ? 'Medium' : 'Low');
        }
      }
      
      // If urgent is toggled, always override to High priority regardless of user selection
      if (isUrgent) {
        finalPriority = 1;
        finalPriorityText = 'High';
      }

      final currentUserId = FirebaseAuthService.currentUser!.id;
      print('💾 Creating collection for user: $currentUserId');
      print('💾 User ID type: ${currentUserId.runtimeType}');
      print('💾 User ID length: ${currentUserId.length}');

      final collection = WasteCollection(
        id: 'collection_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUserId,
        wasteType: wasteType,
        quantity: quantity,
        unit: unit,
        description: description,
        scheduledDate: finalScheduledDate,
        address: address,
        latitude: latitude,
        longitude: longitude,
        status: CollectionStatus.pending, // Start as pending for approval
        createdAt: DateTime.now(),
        notes: notes,
      );

      // Save to Firestore with additional metadata
      final collectionData = collection.toJson();
      collectionData['barangay'] = barangay;
      collectionData['time_slot'] = scheduledTimeSlot;
      collectionData['priority'] = finalPriority;
      collectionData['priority_text'] = finalPriorityText;
      collectionData['category'] = category ?? 'Collection Request';
      collectionData['is_urgent'] = isUrgent;
      collectionData['alternative_dates'] = alternativeDates ?? [];

      print('💾 Saving collection data: $collectionData');

      await _firestore
          .collection('collections')
          .doc(collection.id)
          .set(collectionData);

      print('✅ Collection saved successfully with ID: ${collection.id}');

      // Create notification for the user
      await _createNotification(
        userId: FirebaseAuthService.currentUser!.id,
        title: 'Collection Request Submitted',
        message:
            'Your ${collection.wasteTypeText} collection request has been submitted and is pending approval from barangay officials.',
        type: 'scheduling',
      );

      // Notify barangay officials about the new pending collection request
      await _notifyBarangayOfficialsForApproval(collection, barangay);

      return {
        'success': true,
        'message':
            'Collection request submitted successfully! It will be reviewed by barangay officials.',
        'collection': collection,
        'scheduledDate': scheduledDate,
        'scheduledTimeSlot': scheduledTimeSlot,
        'wasRescheduled':
            scheduledDate != preferredDate ||
            scheduledTimeSlot != preferredTimeSlot,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to schedule collection. Please try again.',
      };
    }
  }

  // Get scheduling preferences for a user
  static Future<Map<String, dynamic>> getUserSchedulingPreferences() async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return {};
      }

      final doc = await _firestore
          .collection('user_preferences')
          .doc(FirebaseAuthService.currentUser!.id)
          .get();

      if (doc.exists) {
        return doc.data()!;
      }

      // Return default preferences
      return {
        'preferred_time_slots': ['08:00-10:00', '10:00-12:00'],
        'preferred_days': [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
        ],
        'auto_reschedule': true,
        'notifications_enabled': true,
        'reminder_hours': 2,
      };
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }

  // Update user scheduling preferences
  static Future<bool> updateUserSchedulingPreferences({
    required List<String> preferredTimeSlots,
    required List<String> preferredDays,
    required bool autoReschedule,
    required bool notificationsEnabled,
    required int reminderHours,
  }) async {
    try {
      if (FirebaseAuthService.currentUser == null) {
        return false;
      }

      await _firestore
          .collection('user_preferences')
          .doc(FirebaseAuthService.currentUser!.id)
          .set({
            'preferred_time_slots': preferredTimeSlots,
            'preferred_days': preferredDays,
            'auto_reschedule': autoReschedule,
            'notifications_enabled': notificationsEnabled,
            'reminder_hours': reminderHours,
            'updated_at': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  // Get collection schedule for a specific date range
  static Future<List<WasteCollection>> getCollectionSchedule({
    required DateTime startDate,
    required DateTime endDate,
    String? barangay,
  }) async {
    try {
      Query query = _firestore
          .collection('collections')
          .where('scheduled_date', isGreaterThanOrEqualTo: startDate)
          .where('scheduled_date', isLessThan: endDate)
          .where('status', whereIn: ['scheduled', 'inProgress']);

      if (barangay != null) {
        query = query.where('barangay', isEqualTo: barangay);
      }

      final querySnapshot = await query.orderBy('scheduled_date').get();

      return querySnapshot.docs
          .map(
            (doc) =>
                WasteCollection.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting collection schedule: $e');
      return [];
    }
  }

  // Reschedule collection
  static Future<Map<String, dynamic>> rescheduleCollection({
    required String collectionId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    try {
      final doc = await _firestore
          .collection('collections')
          .doc(collectionId)
          .get();

      if (!doc.exists) {
        return {'success': false, 'message': 'Collection not found.'};
      }

      final data = doc.data()!;
      final hour = _getHourFromTimeSlot(newTimeSlot);
      final newScheduledDate = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        hour,
        0,
      );

      await _firestore.collection('collections').doc(collectionId).update({
        'scheduled_date': Timestamp.fromDate(newScheduledDate),
        'time_slot': newTimeSlot,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Create notification
      await _createNotification(
        userId: data['user_id'],
        title: 'Collection Rescheduled',
        message:
            'Your collection has been rescheduled to ${newTimeSlot} on ${newDate.day}/${newDate.month}/${newDate.year}.',
        type: 'rescheduling',
      );

      return {
        'success': true,
        'message': 'Collection rescheduled successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reschedule collection. Please try again.',
      };
    }
  }

  // Get scheduling statistics
  static Future<Map<String, dynamic>> getSchedulingStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? barangay,
  }) async {
    try {
      final collections = await getCollectionSchedule(
        startDate: startDate,
        endDate: endDate,
        barangay: barangay,
      );

      final Map<String, int> wasteTypeCounts = {};
      final Map<String, int> timeSlotCounts = {};
      final Map<String, int> statusCounts = {};

      for (final collection in collections) {
        // Count by waste type
        final wasteType = collection.wasteTypeText;
        wasteTypeCounts[wasteType] = (wasteTypeCounts[wasteType] ?? 0) + 1;

        // Count by time slot
        final timeSlot =
            _getTimeSlotForHour(collection.scheduledDate.hour) ?? 'Other';
        timeSlotCounts[timeSlot] = (timeSlotCounts[timeSlot] ?? 0) + 1;

        // Count by status
        final status = collection.statusText;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return {
        'total_collections': collections.length,
        'waste_type_breakdown': wasteTypeCounts,
        'time_slot_breakdown': timeSlotCounts,
        'status_breakdown': statusCounts,
        'average_daily_collections':
            collections.length / endDate.difference(startDate).inDays,
      };
    } catch (e) {
      print('Error getting scheduling statistics: $e');
      return {};
    }
  }

  // Create notification
  static Future<void> _createNotification({
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
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Notify relevant users (drivers and barangay officials) about new scheduled collections
  // Notify barangay officials about pending collection requests
  static Future<void> _notifyBarangayOfficialsForApproval(
    WasteCollection collection,
    String barangay,
  ) async {
    try {
      // Get barangay officials for the specific barangay
      final barangayOfficialsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.barangayOfficial.toString())
          .where('barangay', isEqualTo: barangay)
          .get();

      // Notify barangay officials
      for (final doc in barangayOfficialsSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Collection Request',
          message:
              'New ${collection.wasteTypeText} collection request from ${collection.address} needs approval',
          type: 'pending_approval',
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'quantity': collection.quantity.toString(),
            'scheduled_date': collection.scheduledDate.toIso8601String(),
            'barangay': barangay,
          },
        );
      }
    } catch (e) {
      print('Error notifying barangay officials: $e');
    }
  }

  static Future<void> _notifyRelevantUsers(
    WasteCollection collection,
    String barangay,
  ) async {
    try {
      // Get all drivers
      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.driver.toString())
          .get();

      // Get barangay officials for the specific barangay
      final barangayOfficialsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.barangayOfficial.toString())
          .where('barangay', isEqualTo: barangay)
          .get();

      // Notify drivers
      for (final doc in driversSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Scheduled Collection',
          message:
              'New ${collection.wasteTypeText} collection scheduled for ${barangay} - ${collection.address}',
          type: 'scheduled_collection',
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'barangay': barangay,
            'scheduled_date': collection.scheduledDate.toIso8601String(),
            'quantity': collection.quantity,
            'unit': collection.unit,
            'is_urgent': collection.status == CollectionStatus.pending,
          },
        );
      }

      // Notify barangay officials
      for (final doc in barangayOfficialsSnapshot.docs) {
        await EnhancedNotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Scheduled Collection',
          message:
              'New ${collection.wasteTypeText} collection scheduled in your barangay - ${collection.address}',
          type: 'scheduled_collection',
          data: {
            'collection_id': collection.id,
            'waste_type': collection.wasteTypeText,
            'address': collection.address,
            'barangay': barangay,
            'scheduled_date': collection.scheduledDate.toIso8601String(),
            'quantity': collection.quantity,
            'unit': collection.unit,
            'is_urgent': collection.status == CollectionStatus.pending,
          },
        );
      }

      print(
        'Notified ${driversSnapshot.docs.length} drivers and ${barangayOfficialsSnapshot.docs.length} barangay officials about new scheduled collection',
      );
    } catch (e) {
      print('Error notifying relevant users: $e');
    }
  }
}
