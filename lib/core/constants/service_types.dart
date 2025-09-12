import '../../shared/models/service_type_model.dart';

class ServiceTypes {
  static const List<ServiceType> _serviceTypes = [
    ServiceType(
      name: 'Oil Change',
      duration: 30,
      baseCost: 50.00,
      description: 'Regular engine oil change and filter replacement',
      category: 'Maintenance',
    ),
    ServiceType(
      name: 'Brake Check',
      duration: 60,
      baseCost: 80.00,
      description: 'Complete brake system inspection and adjustment',
      category: 'Safety',
    ),
    ServiceType(
      name: 'Tire Rotation',
      duration: 30,
      baseCost: 40.00,
      description: 'Rotate tires for even wear and extend tire life',
      category: 'Maintenance',
    ),
    ServiceType(
      name: 'Engine Diagnostic',
      duration: 90,
      baseCost: 120.00,
      description: 'Computer diagnostic scan and engine health check',
      category: 'Diagnostic',
    ),
    ServiceType(
      name: 'Transmission Service',
      duration: 120,
      baseCost: 200.00,
      description: 'Transmission fluid change and system service',
      category: 'Major Service',
    ),
    ServiceType(
      name: 'Battery Check',
      duration: 30,
      baseCost: 30.00,
      description: 'Battery health test and terminal cleaning',
      category: 'Maintenance',
    ),
    ServiceType(
      name: 'Air Filter Replacement',
      duration: 30,
      baseCost: 35.00,
      description: 'Replace engine air filter for better performance',
      category: 'Maintenance',
    ),
    ServiceType(
      name: 'Spark Plug Replacement',
      duration: 60,
      baseCost: 90.00,
      description: 'Replace spark plugs for optimal engine performance',
      category: 'Maintenance',
    ),
    ServiceType(
      name: 'Coolant Flush',
      duration: 60,
      baseCost: 75.00,
      description: 'Drain and replace engine coolant system',
      category: 'Maintenance',
    ),
    ServiceType(
      name: 'AC System Check',
      duration: 45,
      baseCost: 60.00,
      description: 'Air conditioning system inspection and service',
      category: 'Comfort',
    ),
    ServiceType(
      name: 'Wheel Alignment',
      duration: 60,
      baseCost: 85.00,
      description: 'Adjust wheel angles for proper tire wear',
      category: 'Safety',
    ),
    ServiceType(
      name: 'Exhaust System Check',
      duration: 45,
      baseCost: 55.00,
      description: 'Inspect exhaust system for leaks and damage',
      category: 'Safety',
    ),
  ];

  static List<ServiceType> get all => _serviceTypes;

  static List<ServiceType> getByCategory(String category) {
    return _serviceTypes
        .where((service) => service.category == category)
        .toList();
  }

  static List<String> get categories {
    return _serviceTypes.map((service) => service.category).toSet().toList();
  }

  static ServiceType? getByName(String name) {
    try {
      return _serviceTypes.firstWhere((service) => service.name == name);
    } catch (e) {
      return null;
    }
  }

  static int calculateTotalDuration(List<String> serviceNames) {
    int totalDuration = 0;
    for (String serviceName in serviceNames) {
      final service = getByName(serviceName);
      if (service != null) {
        totalDuration += service.duration;
      }
    }
    return totalDuration;
  }

  static double calculateTotalCost(List<String> serviceNames) {
    double totalCost = 0.0;
    for (String serviceName in serviceNames) {
      final service = getByName(serviceName);
      if (service != null) {
        totalCost += service.baseCost;
      }
    }
    return totalCost;
  }

  static List<String> generateTimeSlots(String startTime, int duration) {
    final slots = <String>[];
    final start = _timeToMinutes(startTime);

    for (int i = start; i < start + duration; i += 30) {
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

  static int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (e) {
      print('Error parsing time to minutes in ServiceTypes: $e');
    }
    return 0;
  }

  // Working hours configuration - Updated to 9am-7pm Monday-Sunday
  static const Map<String, dynamic> workingHours = {
    'monday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'tuesday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'wednesday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'thursday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'friday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'saturday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'sunday': {'start': '09:00', 'end': '19:00', 'isOpen': true},
    'timeSlotDuration': 30,
    'breakTime': 0,
  };

  // Generate all available time slots for a given day (9am-7pm)
  static List<String> generateAllTimeSlots() {
    final slots = <String>[];

    // Generate slots from 9:00 AM to 7:00 PM (19:00)
    for (int hour = 9; hour < 19; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final nextMinute = minute + 30;
        final nextHour = nextMinute >= 60 ? hour + 1 : hour;
        final nextMinuteAdjusted = nextMinute >= 60
            ? nextMinute - 60
            : nextMinute;
        final nextTime =
            '${nextHour.toString().padLeft(2, '0')}:${nextMinuteAdjusted.toString().padLeft(2, '0')}';
        slots.add('$time-$nextTime');
      }
    }

    // Sort slots chronologically
    slots.sort((a, b) {
      final aStart = a.split('-')[0];
      final bStart = b.split('-')[0];
      return _timeToMinutes(aStart).compareTo(_timeToMinutes(bStart));
    });

    return slots;
  }

  // Check if a date is valid for booking (Monday-Sunday, not more than 1 month ahead)
  static bool isValidBookingDate(DateTime date) {
    final now = DateTime.now();
    final oneMonthFromNow = DateTime(now.year, now.month + 1, now.day);

    // Check if date is not more than 1 month ahead
    if (date.isAfter(oneMonthFromNow)) return false;

    // Check if date is not in the past
    if (date.isBefore(DateTime(now.year, now.month, now.day))) return false;

    return true;
  }

  // Check if a time slot is in the past
  static bool isTimeSlotInPast(String timeSlot, DateTime date) {
    final now = DateTime.now();
    final timeParts = timeSlot.split('-')[0].split(':');

    if (timeParts.length < 2) return true;

    final slotTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    return slotTime.isBefore(now);
  }

  // Get available time slots for a specific date, filtering out past slots
  static List<String> getAvailableTimeSlotsForDate(DateTime date) {
    if (!isValidBookingDate(date)) return [];

    final allSlots = generateAllTimeSlots();
    final now = DateTime.now();

    // If it's today, filter out past time slots
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return allSlots.where((slot) => !isTimeSlotInPast(slot, date)).toList();
    }

    // For future dates, return all slots
    return allSlots;
  }

  // Get available dates for booking (next 30 days, excluding Sundays)
  static List<DateTime> getAvailableDates() {
    final dates = <DateTime>[];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      if (isValidBookingDate(date)) {
        dates.add(date);
      }
    }

    return dates;
  }
}
