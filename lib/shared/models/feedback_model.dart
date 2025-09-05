class Feedback {
  final String id;
  final String appointmentId;
  final String customerId;
  final String workshopId;
  final int rating; // Overall rating (1-5)
  final String? comment;
  final int serviceQuality; // 1-5
  final int timeliness; // 1-5
  final int communication; // 1-5
  final int valueForMoney; // 1-5
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    required this.appointmentId,
    required this.customerId,
    required this.workshopId,
    required this.rating,
    this.comment,
    required this.serviceQuality,
    required this.timeliness,
    required this.communication,
    required this.valueForMoney,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromMap(Map<String, dynamic> map) {
    return Feedback(
      id: map['id'] ?? '',
      appointmentId: map['appointment_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      workshopId: map['workshop_id'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      serviceQuality: map['service_quality'] ?? 0,
      timeliness: map['timeliness'] ?? 0,
      communication: map['communication'] ?? 0,
      valueForMoney: map['value_for_money'] ?? 0,
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
      'appointment_id': appointmentId,
      'customer_id': customerId,
      'workshop_id': workshopId,
      'rating': rating,
      'comment': comment,
      'service_quality': serviceQuality,
      'timeliness': timeliness,
      'communication': communication,
      'value_for_money': valueForMoney,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Feedback copyWith({
    String? id,
    String? appointmentId,
    String? customerId,
    String? workshopId,
    int? rating,
    String? comment,
    int? serviceQuality,
    int? timeliness,
    int? communication,
    int? valueForMoney,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      customerId: customerId ?? this.customerId,
      workshopId: workshopId ?? this.workshopId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      serviceQuality: serviceQuality ?? this.serviceQuality,
      timeliness: timeliness ?? this.timeliness,
      communication: communication ?? this.communication,
      valueForMoney: valueForMoney ?? this.valueForMoney,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get averageRating {
    return (serviceQuality + timeliness + communication + valueForMoney) / 4.0;
  }

  String get ratingText {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String get serviceQualityText {
    if (serviceQuality >= 4.5) return 'Excellent';
    if (serviceQuality >= 3.5) return 'Good';
    if (serviceQuality >= 2.5) return 'Average';
    if (serviceQuality >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String get timelinessText {
    if (timeliness >= 4.5) return 'Excellent';
    if (timeliness >= 3.5) return 'Good';
    if (timeliness >= 2.5) return 'Average';
    if (timeliness >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String get communicationText {
    if (communication >= 4.5) return 'Excellent';
    if (communication >= 3.5) return 'Good';
    if (communication >= 2.5) return 'Average';
    if (communication >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String get valueForMoneyText {
    if (valueForMoney >= 4.5) return 'Excellent';
    if (valueForMoney >= 3.5) return 'Good';
    if (valueForMoney >= 2.5) return 'Average';
    if (valueForMoney >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  bool get hasComment => comment != null && comment!.isNotEmpty;

  @override
  String toString() {
    return 'Feedback(id: $id, rating: $rating, comment: $comment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Feedback && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
