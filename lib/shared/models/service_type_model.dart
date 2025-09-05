class ServiceType {
  final String name;
  final int duration; // Duration in minutes
  final double baseCost;
  final String description;
  final String category;

  const ServiceType({
    required this.name,
    required this.duration,
    required this.baseCost,
    required this.description,
    required this.category,
  });

  factory ServiceType.fromMap(Map<String, dynamic> map) {
    return ServiceType(
      name: map['name'] ?? '',
      duration: map['duration'] ?? 0,
      baseCost: (map['baseCost'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'duration': duration,
      'baseCost': baseCost,
      'description': description,
      'category': category,
    };
  }

  ServiceType copyWith({
    String? name,
    int? duration,
    double? baseCost,
    String? description,
    String? category,
  }) {
    return ServiceType(
      name: name ?? this.name,
      duration: duration ?? this.duration,
      baseCost: baseCost ?? this.baseCost,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  // Helper methods
  String get durationDisplay {
    if (duration < 60) {
      return '${duration}min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  String get costDisplay => '\$${baseCost.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'ServiceType(name: $name, duration: $duration, baseCost: $baseCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceType && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
