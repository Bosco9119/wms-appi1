class BillingItem {
  final String id;
  final String name;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? serviceType;
  final String? category;

  const BillingItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.serviceType,
    this.category,
  });

  factory BillingItem.fromJson(Map<String, dynamic> json) {
    return BillingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      serviceType: json['serviceType'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'serviceType': serviceType,
      'category': category,
    };
  }

  BillingItem copyWith({
    String? id,
    String? name,
    String? description,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? serviceType,
    String? category,
  }) {
    return BillingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      serviceType: serviceType ?? this.serviceType,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'BillingItem(id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice)';
  }
}
