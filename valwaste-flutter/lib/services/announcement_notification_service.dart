import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement.dart';
import 'announcement_service.dart';

class AnnouncementNotificationService {
  final AnnouncementService _service = AnnouncementService();
  StreamSubscription<List<Announcement>>? _subscription;
  String? _lastAnnouncementId;
  BuildContext? _context;

  // Start listening for new announcements
  void startListening(BuildContext context) {
    _context = context;

    // Load last seen announcement ID
    _loadLastAnnouncementId();

    _subscription = _service.getActiveAnnouncements().listen((announcements) {
      if (announcements.isNotEmpty) {
        final latest = announcements.first;

        // Check if this is a new announcement
        if (_lastAnnouncementId != null && _lastAnnouncementId != latest.id) {
          _showNotification(latest);
        }

        // Update last seen announcement ID
        _lastAnnouncementId = latest.id;
        _saveLastAnnouncementId(latest.id);
      }
    });
  }

  // Stop listening for announcements
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // Show notification for new announcement
  void _showNotification(Announcement announcement) {
    if (_context == null || !_context!.mounted) return;

    // Show SnackBar notification
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.announcement, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Announcement',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    announcement.message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // You can navigate to a detailed announcement screen here
            _showAnnouncementDialog(announcement);
          },
        ),
      ),
    );
  }

  // Show announcement dialog
  void _showAnnouncementDialog(Announcement announcement) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.announcement, color: Colors.blue[700], size: 24),
            const SizedBox(width: 8),
            const Text('Announcement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.message,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    announcement.createdBy,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    announcement.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Load last seen announcement ID from SharedPreferences
  Future<void> _loadLastAnnouncementId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastAnnouncementId = prefs.getString('last_announcement_id');
    } catch (e) {
      print('Error loading last announcement ID: $e');
    }
  }

  // Save last seen announcement ID to SharedPreferences
  Future<void> _saveLastAnnouncementId(String announcementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_announcement_id', announcementId);
    } catch (e) {
      print('Error saving last announcement ID: $e');
    }
  }

  // Check if there are unread announcements
  Future<bool> hasUnreadAnnouncements() async {
    try {
      final latestAnnouncement = await _service.getLatestAnnouncement();
      if (latestAnnouncement == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastSeenId = prefs.getString('last_announcement_id');

      return lastSeenId != latestAnnouncement.id;
    } catch (e) {
      print('Error checking unread announcements: $e');
      return false;
    }
  }

  // Mark all announcements as read
  Future<void> markAllAsRead() async {
    try {
      final latestAnnouncement = await _service.getLatestAnnouncement();
      if (latestAnnouncement != null) {
        await _saveLastAnnouncementId(latestAnnouncement.id);
        _lastAnnouncementId = latestAnnouncement.id;
      }
    } catch (e) {
      print('Error marking announcements as read: $e');
    }
  }
}

