enum CollectionStatus {
  pending, // Resident submitted, waiting for barangay approval
  approved, // Barangay official approved, waiting for admin scheduling
  scheduled, // Admin scheduled for collection
  inProgress, // Driver is collecting
  completed, // Collection completed
  cancelled, // Request cancelled
  rejected, // Barangay official rejected
}

enum WasteType { general, recyclable, organic, hazardous, electronic }

class WasteCollection {
  final String id;
  final String userId;
  final WasteType wasteType;
  final double quantity;
  final String unit;
  final String description;
  final DateTime scheduledDate;
  final String address;
  final double? latitude;
  final double? longitude;
  final CollectionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final String? assignedTo;
  final String? assignedRole;
  final DateTime? assignedAt;
  final String? approvedBy; // Barangay official who approved
  final DateTime? approvedAt; // When it was approved
  final String? scheduledBy; // Admin who scheduled
  final DateTime? scheduledAt; // When it was scheduled
  final String? rejectionReason; // Reason for rejection
  final String? barangay; // Barangay where request was made

  WasteCollection({
    required this.id,
    required this.userId,
    required this.wasteType,
    required this.quantity,
    required this.unit,
    required this.description,
    required this.scheduledDate,
    required this.address,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.assignedTo,
    this.assignedRole,
    this.assignedAt,
    this.approvedBy,
    this.approvedAt,
    this.scheduledBy,
    this.scheduledAt,
    this.rejectionReason,
    this.barangay,
  });

  factory WasteCollection.fromJson(Map<String, dynamic> json) {
    return WasteCollection(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      wasteType: WasteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['waste_type'],
        orElse: () => WasteType.general,
      ),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? 'kg',
      description: json['description'] ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : DateTime.now(),
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: CollectionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => CollectionStatus.pending,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      notes: json['notes'],
      assignedTo: json['assigned_to'],
      assignedRole: json['assigned_role'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      scheduledBy: json['scheduled_by'],
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      barangay: json['barangay'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'waste_type': wasteType.toString().split('.').last,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'assigned_to': assignedTo,
      'assigned_role': assignedRole,
      'assigned_at': assignedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'scheduled_by': scheduledBy,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'barangay': barangay,
    };
  }

  String get statusText {
    switch (status) {
      case CollectionStatus.pending:
        return 'Pending Approval';
      case CollectionStatus.approved:
        return 'Approved by Barangay';
      case CollectionStatus.scheduled:
        return 'Scheduled for Collection';
      case CollectionStatus.inProgress:
        return 'In Progress';
      case CollectionStatus.completed:
        return 'Completed';
      case CollectionStatus.cancelled:
        return 'Cancelled';
      case CollectionStatus.rejected:
        return 'Rejected';
    }
  }

  String get wasteTypeText {
    switch (wasteType) {
      case WasteType.general:
        return 'General Waste';
      case WasteType.recyclable:
        return 'Recyclable';
      case WasteType.organic:
        return 'Organic Waste';
      case WasteType.hazardous:
        return 'Hazardous Waste';
      case WasteType.electronic:
        return 'Electronic Waste';
    }
  }
}
