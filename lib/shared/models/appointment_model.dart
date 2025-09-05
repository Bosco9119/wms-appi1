class Appointment {
  final String id;
  final String customerId;
  final String vehicleId;
  final String workshopId;
  final String workshopName;
  final String serviceType;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? description;
  final int? estimatedDuration; // in minutes
  final int? actualDuration; // in minutes
  final double? totalCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.workshopId,
    required this.workshopName,
    required this.serviceType,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.description,
    this.estimatedDuration,
    this.actualDuration,
    this.totalCost,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      customerId: map['customer_id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      workshopId: map['workshop_id'] ?? '',
      workshopName: map['workshop_name'] ?? '',
      serviceType: map['service_type'] ?? '',
      appointmentDate: DateTime.parse(
        map['appointment_date'] ?? DateTime.now().toIso8601String(),
      ),
      appointmentTime: map['appointment_time'] ?? '',
      status: map['status'] ?? 'Scheduled',
      description: map['description'],
      estimatedDuration: map['estimated_duration'],
      actualDuration: map['actual_duration'],
      totalCost: map['total_cost']?.toDouble(),
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'workshop_id': workshopId,
      'workshop_name': workshopName,
      'service_type': serviceType,
      'appointment_date': appointmentDate.toIso8601String(),
      'appointment_time': appointmentTime,
      'status': status,
      'description': description,
      'estimated_duration': estimatedDuration,
      'actual_duration': actualDuration,
      'total_cost': totalCost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    String? workshopId,
    String? workshopName,
    String? serviceType,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? status,
    String? description,
    int? estimatedDuration,
    int? actualDuration,
    double? totalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      serviceType: serviceType ?? this.serviceType,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      totalCost: totalCost ?? this.totalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) &&
      status != 'Completed' &&
      status != 'Cancelled';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
  bool get isInProgress =>
      ['In Inspection', 'Parts Awaiting', 'In Repair'].contains(status);

  String get statusDisplayName {
    switch (status) {
      case 'Scheduled':
        return 'Scheduled';
      case 'In Inspection':
        return 'In Inspection';
      case 'Parts Awaiting':
        return 'Parts Awaiting';
      case 'In Repair':
        return 'In Repair';
      case 'Ready for Collection':
        return 'Ready for Collection';
      case 'Completed':
        return 'Completed';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  String get formattedDateTime {
    return '$formattedDate at $appointmentTime';
  }

  @override
  String toString() {
    return 'Appointment(id: $id, workshopName: $workshopName, serviceType: $serviceType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
