class NotificationPreferences {
  final bool isEnabled;
  final List<ReminderInterval> reminderIntervals;
  final DateTime lastUpdated;

  const NotificationPreferences({
    required this.isEnabled,
    required this.reminderIntervals,
    required this.lastUpdated,
  });

  factory NotificationPreferences.defaultSettings() {
    return NotificationPreferences(
      isEnabled: true,
      reminderIntervals: [
        ReminderInterval.fiveSeconds,
      ], // Default 5-second reminder for testing
      lastUpdated: DateTime.now(),
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      isEnabled: json['isEnabled'] ?? true,
      reminderIntervals:
          (json['reminderIntervals'] as List<dynamic>?)
              ?.map((e) => ReminderInterval.fromJson(e))
              .toList() ??
          [ReminderInterval.fiveSeconds],
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'reminderIntervals': reminderIntervals.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  NotificationPreferences copyWith({
    bool? isEnabled,
    List<ReminderInterval>? reminderIntervals,
    DateTime? lastUpdated,
  }) {
    return NotificationPreferences(
      isEnabled: isEnabled ?? this.isEnabled,
      reminderIntervals: reminderIntervals ?? this.reminderIntervals,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ReminderInterval {
  final String id;
  final String displayName;
  final Duration duration;
  final bool isEnabled;

  const ReminderInterval({
    required this.id,
    required this.displayName,
    required this.duration,
    this.isEnabled = true,
  });

  // Predefined reminder intervals (TESTING VERSION - Short intervals)
  static const ReminderInterval oneSecond = ReminderInterval(
    id: '1s',
    displayName: '1 Second',
    duration: Duration(seconds: 1),
  );

  static const ReminderInterval threeSeconds = ReminderInterval(
    id: '3s',
    displayName: '3 Seconds',
    duration: Duration(seconds: 3),
  );

  static const ReminderInterval fiveSeconds = ReminderInterval(
    id: '5s',
    displayName: '5 Seconds',
    duration: Duration(seconds: 5),
  );

  static const ReminderInterval tenSeconds = ReminderInterval(
    id: '10s',
    displayName: '10 Seconds',
    duration: Duration(seconds: 10),
  );

  // Production intervals (commented out for testing)
  static const ReminderInterval oneHour = ReminderInterval(
    id: '1h',
    displayName: '1 Hour',
    duration: Duration(hours: 1),
  );

  static const ReminderInterval twoHours = ReminderInterval(
    id: '2h',
    displayName: '2 Hours',
    duration: Duration(hours: 2),
  );

  static const ReminderInterval threeHours = ReminderInterval(
    id: '3h',
    displayName: '3 Hours',
    duration: Duration(hours: 3),
  );

  static const ReminderInterval oneDay = ReminderInterval(
    id: '1d',
    displayName: '1 Day',
    duration: Duration(days: 1),
  );

  static const ReminderInterval threeDays = ReminderInterval(
    id: '3d',
    displayName: '3 Days',
    duration: Duration(days: 3),
  );

  static const ReminderInterval oneWeek = ReminderInterval(
    id: '1w',
    displayName: '1 Week',
    duration: Duration(days: 7),
  );

  // All available intervals (TESTING VERSION)
  static const List<ReminderInterval> allIntervals = [
    oneSecond,
    threeSeconds,
    fiveSeconds,
    tenSeconds,
    // Production intervals (uncomment for production)
    // oneHour,
    // twoHours,
    // threeHours,
    // oneDay,
    // threeDays,
    // oneWeek,
  ];

  factory ReminderInterval.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final isEnabled = json['isEnabled'] ?? true;

    // Find the interval by ID
    final interval = allIntervals.firstWhere(
      (interval) => interval.id == id,
      orElse: () => twoHours, // Default fallback
    );

    return ReminderInterval(
      id: interval.id,
      displayName: interval.displayName,
      duration: interval.duration,
      isEnabled: isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'isEnabled': isEnabled};
  }

  ReminderInterval copyWith({bool? isEnabled}) {
    return ReminderInterval(
      id: id,
      displayName: displayName,
      duration: duration,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderInterval && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => displayName;
}
