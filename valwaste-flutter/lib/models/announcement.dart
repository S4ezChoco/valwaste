import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String message;
  final DateTime createdAt;
  final Timestamp expiresAt;
  final String createdBy;
  final bool isActive;

  Announcement({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.expiresAt,
    required this.createdBy,
    required this.isActive,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Announcement(
      id: doc.id,
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] as Timestamp,
      createdBy: data['createdBy'] ?? 'Administrator',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt,
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  bool get isExpired {
    return expiresAt.toDate().isBefore(DateTime.now());
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
}

