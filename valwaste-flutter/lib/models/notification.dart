import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  collectionRequest,
  collectionApproved,
  collectionDeclined,
  collectionAssigned,
  routeUpdate,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>?
  data; // Additional data like collection ID, route info, etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseType(data['type']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  static NotificationType _parseType(dynamic typeData) {
    if (typeData == null) return NotificationType.collectionRequest;

    String typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'collection_request':
        return NotificationType.collectionRequest;
      case 'collection_approved':
        return NotificationType.collectionApproved;
      case 'collection_declined':
        return NotificationType.collectionDeclined;
      case 'collection_assigned':
        return NotificationType.collectionAssigned;
      case 'route_update':
        return NotificationType.routeUpdate;
      default:
        return NotificationType.collectionRequest;
    }
  }

  String get typeString {
    switch (type) {
      case NotificationType.collectionRequest:
        return 'collection_request';
      case NotificationType.collectionApproved:
        return 'collection_approved';
      case NotificationType.collectionDeclined:
        return 'collection_declined';
      case NotificationType.collectionAssigned:
        return 'collection_assigned';
      case NotificationType.routeUpdate:
        return 'route_update';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': typeString,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'data': data,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
