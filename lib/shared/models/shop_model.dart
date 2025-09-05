class Shop {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phoneNumber;
  final String email;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final Map<String, int>
  serviceCounts; // e.g., {"Engines Service": 2800, "Transmission": 1900}
  final List<String> services; // Available services
  final double latitude;
  final double longitude;
  final bool isOpen;
  final String operatingHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.serviceCounts,
    required this.services,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.operatingHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      email: map['email'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['review_count'] ?? 0,
      serviceCounts: Map<String, int>.from(map['service_counts'] ?? {}),
      services: List<String>.from(map['services'] ?? []),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      isOpen: map['is_open'] ?? true,
      operatingHours: map['operating_hours'] ?? '',
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
      'name': name,
      'description': description,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'image_urls': imageUrls,
      'rating': rating,
      'review_count': reviewCount,
      'service_counts': serviceCounts,
      'services': services,
      'latitude': latitude,
      'longitude': longitude,
      'is_open': isOpen,
      'operating_hours': operatingHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Shop copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? email,
    List<String>? imageUrls,
    double? rating,
    int? reviewCount,
    Map<String, int>? serviceCounts,
    List<String>? services,
    double? latitude,
    double? longitude,
    bool? isOpen,
    String? operatingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imageUrls: imageUrls ?? this.imageUrls,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      serviceCounts: serviceCounts ?? this.serviceCounts,
      services: services ?? this.services,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen ?? this.isOpen,
      operatingHours: operatingHours ?? this.operatingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
