enum CollectionStatus { pending, scheduled, inProgress, completed, cancelled }

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
  final CollectionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  WasteCollection({
    required this.id,
    required this.userId,
    required this.wasteType,
    required this.quantity,
    required this.unit,
    required this.description,
    required this.scheduledDate,
    required this.address,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
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
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  String get statusText {
    switch (status) {
      case CollectionStatus.pending:
        return 'Pending';
      case CollectionStatus.scheduled:
        return 'Scheduled';
      case CollectionStatus.inProgress:
        return 'In Progress';
      case CollectionStatus.completed:
        return 'Completed';
      case CollectionStatus.cancelled:
        return 'Cancelled';
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
