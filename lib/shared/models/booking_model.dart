import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { confirmed, cancelled, completed, inProgress }

class Booking {
  final String id;
  final String shopId;
  final String userId;
  final String date;
  final String timeSlot;
  final List<String> serviceTypes;
  final int totalDuration; // Total minutes for all services
  final BookingStatus status;
  final String? vehicleId;
  final String? notes;
  final double estimatedCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized data for easier queries
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  const Booking({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.serviceTypes,
    required this.totalDuration,
    required this.status,
    this.vehicleId,
    this.notes,
    required this.estimatedCost,
    required this.createdAt,
    required this.updatedAt,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      shopId: map['shopId'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      serviceTypes: List<String>.from(map['serviceTypes'] ?? []),
      totalDuration: map['totalDuration'] ?? 0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      vehicleId: map['vehicleId'],
      notes: map['notes'],
      estimatedCost: (map['estimatedCost'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shopName: map['shopName'] ?? '',
      shopAddress: map['shopAddress'] ?? '',
      shopPhone: map['shopPhone'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'userId': userId,
      'date': date,
      'timeSlot': timeSlot,
      'serviceTypes': serviceTypes,
      'totalDuration': totalDuration,
      'status': status.name,
      'vehicleId': vehicleId,
      'notes': notes,
      'estimatedCost': estimatedCost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'shopName': shopName,
      'shopAddress': shopAddress,
      'shopPhone': shopPhone,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
    };
  }

  Booking copyWith({
    String? id,
    String? shopId,
    String? userId,
    String? date,
    String? timeSlot,
    List<String>? serviceTypes,
    int? totalDuration,
    BookingStatus? status,
    String? vehicleId,
    String? notes,
    double? estimatedCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    return Booking(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      totalDuration: totalDuration ?? this.totalDuration,
      status: status ?? this.status,
      vehicleId: vehicleId ?? this.vehicleId,
      notes: notes ?? this.notes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }

  // Helper methods
  bool get canCancel {
    final now = DateTime.now();
    final bookingDateTime = DateTime.parse(date);
    final timeParts = timeSlot.split('-')[0].split(':');
    final bookingTime = DateTime(
      bookingDateTime.year,
      bookingDateTime.month,
      bookingDateTime.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    // Can cancel if more than 1 hour before appointment
    return bookingTime.difference(now).inHours >= 1;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final bookingDateTime = DateTime.parse(date);
    final timeParts = timeSlot.split('-')[0].split(':');
    final bookingTime = DateTime(
      bookingDateTime.year,
      bookingDateTime.month,
      bookingDateTime.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    return bookingTime.isAfter(now) && status == BookingStatus.confirmed;
  }

  String get statusDisplayName {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.inProgress:
        return 'In Progress';
    }
  }

  @override
  String toString() {
    return 'Booking(id: $id, shopId: $shopId, userId: $userId, date: $date, timeSlot: $timeSlot, serviceTypes: $serviceTypes, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
