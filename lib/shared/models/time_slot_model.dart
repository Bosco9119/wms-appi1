class TimeSlot {
  final String time;
  final bool isAvailable;
  final String? bookingId;
  final List<String>? serviceTypes;

  const TimeSlot({
    required this.time,
    required this.isAvailable,
    this.bookingId,
    this.serviceTypes,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    final time = map['time'] ?? '';
    return TimeSlot(
      time: time,
      isAvailable: map['isAvailable'] ?? false,
      bookingId: map['bookingId'],
      serviceTypes: map['serviceTypes'] != null
          ? List<String>.from(map['serviceTypes'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'isAvailable': isAvailable,
      'bookingId': bookingId,
      'serviceTypes': serviceTypes,
    };
  }

  TimeSlot copyWith({
    String? time,
    bool? isAvailable,
    String? bookingId,
    List<String>? serviceTypes,
  }) {
    return TimeSlot(
      time: time ?? this.time,
      isAvailable: isAvailable ?? this.isAvailable,
      bookingId: bookingId ?? this.bookingId,
      serviceTypes: serviceTypes ?? this.serviceTypes,
    );
  }

  // Helper methods
  String get startTime {
    try {
      final parts = time.split('-');
      return parts.isNotEmpty ? parts[0] : '';
    } catch (e) {
      print('❌ Error in startTime getter: $e, time="$time"');
      return '';
    }
  }

  String get endTime {
    try {
      final parts = time.split('-');
      return parts.length > 1 ? parts[1] : '';
    } catch (e) {
      print('❌ Error in endTime getter: $e, time="$time"');
      return '';
    }
  }

  bool get isMorningSlot {
    try {
      final startTimeParts = startTime.split(':');
      if (startTimeParts.length >= 2) {
        final startHour = int.parse(startTimeParts[0]);
        return startHour >= 10 && startHour < 12;
      }
    } catch (e) {
      print('❌ Error parsing morning slot: $e, startTime="$startTime"');
    }
    return false;
  }

  bool get isAfternoonSlot {
    try {
      final startTimeParts = startTime.split(':');
      if (startTimeParts.length >= 2) {
        final startHour = int.parse(startTimeParts[0]);
        return startHour >= 13 && startHour < 16;
      }
    } catch (e) {
      print('❌ Error parsing afternoon slot: $e, startTime="$startTime"');
    }
    return false;
  }

  @override
  String toString() {
    return 'TimeSlot(time: $time, isAvailable: $isAvailable, bookingId: $bookingId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.time == time;
  }

  @override
  int get hashCode => time.hashCode;
}
