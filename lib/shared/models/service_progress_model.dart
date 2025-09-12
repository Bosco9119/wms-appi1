import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceStatus {
  scheduled, // Appointment scheduled
  inInspection, // Vehicle being inspected
  partsAwaiting, // Waiting for parts
  inRepair, // Currently being repaired
  qualityCheck, // Final quality check
  readyForCollection, // Ready for customer pickup
  completed, // Service completed
  cancelled, // Service cancelled
}

class ServiceProgress {
  final String id;
  final String bookingId;
  final String shopId;
  final String userId;
  final String vehicleId;
  final List<String> serviceTypes;
  final ServiceStatus currentStatus;
  final List<ServiceStatusUpdate> statusHistory;
  final String? currentNotes;
  final String? estimatedCompletionTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized data for easier queries
  final String shopName;
  final String customerName;
  final String customerPhone;
  final String vehicleModel;
  final String vehiclePlate;

  const ServiceProgress({
    required this.id,
    required this.bookingId,
    required this.shopId,
    required this.userId,
    required this.vehicleId,
    required this.serviceTypes,
    required this.currentStatus,
    required this.statusHistory,
    this.currentNotes,
    this.estimatedCompletionTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.createdAt,
    required this.updatedAt,
    required this.shopName,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleModel,
    required this.vehiclePlate,
  });

  factory ServiceProgress.fromMap(Map<String, dynamic> map) {
    return ServiceProgress(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      shopId: map['shopId'] ?? '',
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      serviceTypes: List<String>.from(map['serviceTypes'] ?? []),
      currentStatus: ServiceStatus.values.firstWhere(
        (e) => e.name == map['currentStatus'],
        orElse: () => ServiceStatus.scheduled,
      ),
      statusHistory:
          (map['statusHistory'] as List<dynamic>?)
              ?.map(
                (item) =>
                    ServiceStatusUpdate.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      currentNotes: map['currentNotes'],
      estimatedCompletionTime: map['estimatedCompletionTime'],
      actualStartTime: (map['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (map['actualEndTime'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shopName: map['shopName'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'shopId': shopId,
      'userId': userId,
      'vehicleId': vehicleId,
      'serviceTypes': serviceTypes,
      'currentStatus': currentStatus.name,
      'statusHistory': statusHistory.map((update) => update.toMap()).toList(),
      'currentNotes': currentNotes,
      'estimatedCompletionTime': estimatedCompletionTime,
      'actualStartTime': actualStartTime != null
          ? Timestamp.fromDate(actualStartTime!)
          : null,
      'actualEndTime': actualEndTime != null
          ? Timestamp.fromDate(actualEndTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'shopName': shopName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate,
    };
  }

  ServiceProgress copyWith({
    String? id,
    String? bookingId,
    String? shopId,
    String? userId,
    String? vehicleId,
    List<String>? serviceTypes,
    ServiceStatus? currentStatus,
    List<ServiceStatusUpdate>? statusHistory,
    String? currentNotes,
    String? estimatedCompletionTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shopName,
    String? customerName,
    String? customerPhone,
    String? vehicleModel,
    String? vehiclePlate,
  }) {
    return ServiceProgress(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      currentStatus: currentStatus ?? this.currentStatus,
      statusHistory: statusHistory ?? this.statusHistory,
      currentNotes: currentNotes ?? this.currentNotes,
      estimatedCompletionTime:
          estimatedCompletionTime ?? this.estimatedCompletionTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopName: shopName ?? this.shopName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    );
  }

  // Helper methods
  String get statusDisplayName {
    switch (currentStatus) {
      case ServiceStatus.scheduled:
        return 'Scheduled';
      case ServiceStatus.inInspection:
        return 'In Inspection';
      case ServiceStatus.partsAwaiting:
        return 'Parts Awaiting';
      case ServiceStatus.inRepair:
        return 'In Repair';
      case ServiceStatus.qualityCheck:
        return 'Quality Check';
      case ServiceStatus.readyForCollection:
        return 'Ready for Collection';
      case ServiceStatus.completed:
        return 'Completed';
      case ServiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusDescription {
    switch (currentStatus) {
      case ServiceStatus.scheduled:
        return 'Your vehicle service is scheduled';
      case ServiceStatus.inInspection:
        return 'Our technicians are inspecting your vehicle';
      case ServiceStatus.partsAwaiting:
        return 'We are waiting for required parts to arrive';
      case ServiceStatus.inRepair:
        return 'Your vehicle is being repaired';
      case ServiceStatus.qualityCheck:
        return 'Final quality check in progress';
      case ServiceStatus.readyForCollection:
        return 'Your vehicle is ready for collection';
      case ServiceStatus.completed:
        return 'Service completed successfully';
      case ServiceStatus.cancelled:
        return 'Service has been cancelled';
    }
  }

  int get progressPercentage {
    switch (currentStatus) {
      case ServiceStatus.scheduled:
        return 10;
      case ServiceStatus.inInspection:
        return 25;
      case ServiceStatus.partsAwaiting:
        return 40;
      case ServiceStatus.inRepair:
        return 60;
      case ServiceStatus.qualityCheck:
        return 80;
      case ServiceStatus.readyForCollection:
        return 95;
      case ServiceStatus.completed:
        return 100;
      case ServiceStatus.cancelled:
        return 0;
    }
  }

  bool get isActive {
    return currentStatus != ServiceStatus.completed &&
        currentStatus != ServiceStatus.cancelled;
  }

  Duration? get estimatedTimeRemaining {
    if (estimatedCompletionTime == null || actualStartTime == null) return null;

    final now = DateTime.now();
    final estimatedEnd = DateTime.parse(estimatedCompletionTime!);

    if (estimatedEnd.isBefore(now)) return Duration.zero;

    return estimatedEnd.difference(now);
  }

  @override
  String toString() {
    return 'ServiceProgress(id: $id, bookingId: $bookingId, currentStatus: $currentStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ServiceStatusUpdate {
  final ServiceStatus status;
  final String? notes;
  final DateTime timestamp;
  final String updatedBy; // Shop staff member name or system

  const ServiceStatusUpdate({
    required this.status,
    this.notes,
    required this.timestamp,
    required this.updatedBy,
  });

  factory ServiceStatusUpdate.fromMap(Map<String, dynamic> map) {
    return ServiceStatusUpdate(
      status: ServiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ServiceStatus.scheduled,
      ),
      notes: map['notes'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? 'System',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedBy': updatedBy,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case ServiceStatus.scheduled:
        return 'Scheduled';
      case ServiceStatus.inInspection:
        return 'In Inspection';
      case ServiceStatus.partsAwaiting:
        return 'Parts Awaiting';
      case ServiceStatus.inRepair:
        return 'In Repair';
      case ServiceStatus.qualityCheck:
        return 'Quality Check';
      case ServiceStatus.readyForCollection:
        return 'Ready for Collection';
      case ServiceStatus.completed:
        return 'Completed';
      case ServiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}
