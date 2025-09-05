import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_slot_model.dart';

class ShopAvailability {
  final String shopId;
  final String date;
  final Map<String, TimeSlot> timeSlots;
  final DateTime lastUpdated;

  const ShopAvailability({
    required this.shopId,
    required this.date,
    required this.timeSlots,
    required this.lastUpdated,
  });

  factory ShopAvailability.fromMap(
    Map<String, dynamic> map,
    String shopId,
    String date,
  ) {
    final timeSlotsMap = map['timeSlots'] as Map<String, dynamic>? ?? {};

    final timeSlots = timeSlotsMap.map((key, value) {
      // Add the time key to the value map
      final slotData = Map<String, dynamic>.from(value);
      slotData['time'] = key; // The key is the time slot (e.g., "10:00-10:30")
      return MapEntry(key, TimeSlot.fromMap(slotData));
    });

    return ShopAvailability(
      shopId: shopId,
      date: date,
      timeSlots: timeSlots,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeSlots': timeSlots.map((key, value) => MapEntry(key, value.toMap())),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  ShopAvailability copyWith({
    String? shopId,
    String? date,
    Map<String, TimeSlot>? timeSlots,
    DateTime? lastUpdated,
  }) {
    return ShopAvailability(
      shopId: shopId ?? this.shopId,
      date: date ?? this.date,
      timeSlots: timeSlots ?? this.timeSlots,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods
  List<TimeSlot> get availableSlots {
    return timeSlots.values.where((slot) => slot.isAvailable).toList();
  }

  List<TimeSlot> get bookedSlots {
    return timeSlots.values.where((slot) => !slot.isAvailable).toList();
  }

  bool isSlotAvailable(String timeSlot) {
    return timeSlots[timeSlot]?.isAvailable ?? false;
  }

  TimeSlot? getSlot(String timeSlot) {
    return timeSlots[timeSlot];
  }

  // Check if a time range is available for booking
  bool isTimeRangeAvailable(String startTime, int duration) {
    try {
      final timeParts = startTime.split(':');
      if (timeParts.length < 2) return false;

      final startHour = int.parse(timeParts[0]);
      final startMinute = int.parse(timeParts[1]);

      // Calculate end time
      final totalMinutes = startHour * 60 + startMinute + duration;
      final endHour = totalMinutes ~/ 60;
      final endMinute = totalMinutes % 60;
      final endTime =
          '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

      // Check if all required slots are available
      final requiredSlots = _generateTimeSlots(startTime, endTime);
      return requiredSlots.every((slot) => isSlotAvailable(slot));
    } catch (e) {
      print('Error in isTimeRangeAvailable: $e');
      return false;
    }
  }

  // Generate time slots between start and end time
  List<String> _generateTimeSlots(String startTime, String endTime) {
    final slots = <String>[];
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    for (int i = start; i < end; i += 30) {
      // 30-minute intervals
      final hour = i ~/ 60;
      final minute = i % 60;
      final time =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      final nextTime =
          '${((i + 30) ~/ 60).toString().padLeft(2, '0')}:${((i + 30) % 60).toString().padLeft(2, '0')}';
      slots.add('$time-$nextTime');
    }

    return slots;
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (e) {
      print('Error parsing time to minutes: $e');
    }
    return 0;
  }

  @override
  String toString() {
    return 'ShopAvailability(shopId: $shopId, date: $date, availableSlots: ${availableSlots.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopAvailability &&
        other.shopId == shopId &&
        other.date == date;
  }

  @override
  int get hashCode => shopId.hashCode ^ date.hashCode;
}
