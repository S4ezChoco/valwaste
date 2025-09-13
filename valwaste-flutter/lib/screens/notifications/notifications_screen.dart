import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_notification_service.dart';
import '../../services/enhanced_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  Map<String, dynamic> _notificationPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadNotificationPreferences();
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() {
    // Listen to real-time notifications
    EnhancedNotificationService.getUserNotificationsStream().listen((
      notifications,
    ) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    });

    // Listen to unread count
    EnhancedNotificationService.getUnreadNotificationCountStream().listen((
      count,
    ) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications =
          await FirebaseNotificationService.getUserNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final preferences =
          await EnhancedNotificationService.getNotificationPreferences();
      setState(() {
        _notificationPreferences = preferences;
      });
    } catch (e) {
      print('Error loading notification preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showNotificationSettings,
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      '${_notifications.length}',
                      Icons.notifications,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: _buildStatCard(
                      'Unread',
                      '$_unreadCount',
                      Icons.mark_email_unread,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          Text(
                            'No notifications',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'You\'re all caught up!',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isRead = notification.isRead;
    final timestamp = notification.createdAt;
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: isRead
            ? Border.all(color: AppColors.divider)
            : Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          notification.title,
          style: AppTextStyles.body1.copyWith(
            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
            color: isRead ? AppColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              notification.message,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              _formatTimestamp(timestamp),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          _markAsRead(notification.id);
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'collection':
        return Icons.local_shipping;
      case 'announcement':
        return Icons.campaign;
      case 'tip':
        return Icons.lightbulb;
      case 'welcome':
        return Icons.celebration;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'collection':
        return AppColors.primary;
      case 'announcement':
        return AppColors.secondary;
      case 'tip':
        return AppColors.secondary;
      case 'welcome':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  void _markAsRead(String notificationId) async {
    try {
      await FirebaseNotificationService.markNotificationAsRead(notificationId);
      await _loadNotifications(); // Reload to update UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notification as read: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _markAllAsRead() async {
    try {
      await FirebaseNotificationService.markAllNotificationsAsRead();
      await _loadNotifications(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationSettingsSheet(
        preferences: _notificationPreferences,
        onPreferencesChanged: (preferences) {
          setState(() {
            _notificationPreferences = preferences;
          });
        },
      ),
    );
  }
}

class NotificationSettingsSheet extends StatefulWidget {
  final Map<String, dynamic> preferences;
  final Function(Map<String, dynamic>) onPreferencesChanged;

  const NotificationSettingsSheet({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  late bool _enabled;
  late bool _collectionReminders;
  late bool _statusUpdates;
  late bool _announcements;
  late int _reminderHours;

  @override
  void initState() {
    super.initState();
    _enabled = widget.preferences['enabled'] ?? true;
    _collectionReminders = widget.preferences['collection_reminders'] ?? true;
    _statusUpdates = widget.preferences['status_updates'] ?? true;
    _announcements = widget.preferences['announcements'] ?? true;
    _reminderHours = widget.preferences['reminder_hours'] ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Notification Settings',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Enable/Disable Notifications
          _buildSettingTile(
            title: 'Enable Notifications',
            subtitle: 'Receive push notifications',
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),

          if (_enabled) ...[
            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'Collection Reminders',
              subtitle: 'Reminders for scheduled collections',
              value: _collectionReminders,
              onChanged: (value) {
                setState(() {
                  _collectionReminders = value;
                });
              },
            ),

            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'Status Updates',
              subtitle: 'Updates on collection status',
              value: _statusUpdates,
              onChanged: (value) {
                setState(() {
                  _statusUpdates = value;
                });
              },
            ),

            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'Announcements',
              subtitle: 'Important announcements and tips',
              value: _announcements,
              onChanged: (value) {
                setState(() {
                  _announcements = value;
                });
              },
            ),

            const SizedBox(height: 20),
            Text(
              'Reminder Time',
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Slider(
              value: _reminderHours.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _reminderHours = value.round();
                });
              },
            ),
            Text(
              '$_reminderHours hours before collection',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    try {
      final success =
          await EnhancedNotificationService.updateNotificationPreferences(
            enabled: _enabled,
            collectionReminders: _collectionReminders,
            statusUpdates: _statusUpdates,
            announcements: _announcements,
            reminderHours: _reminderHours,
          );

      if (success) {
        widget.onPreferencesChanged({
          'enabled': _enabled,
          'collection_reminders': _collectionReminders,
          'status_updates': _statusUpdates,
          'announcements': _announcements,
          'reminder_hours': _reminderHours,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings saved'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save settings'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
